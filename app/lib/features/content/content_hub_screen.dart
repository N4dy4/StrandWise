import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/content_repository.dart';
import '../../models/content_item.dart';
import '../../models/hair_profile.dart';
import '../../models/product.dart';
import '../../services/content_ranker.dart';
import '../../services/ingredient_flagger.dart';
import '../../theme/app_theme.dart';

const medicalDisclaimer =
    'Not medical advice. For hair loss or scalp conditions, see a doctor or dermatologist.';

Future<void> openSource(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

class ContentHubScreen extends StatelessWidget {
  const ContentHubScreen({super.key, required this.profile, this.repository});

  final HairProfile profile;
  final ContentRepository? repository;

  @override
  Widget build(BuildContext context) {
    final repo = repository ?? ContentRepository.create();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Discover'),
          bottom: const TabBar(
            tabs: [Tab(text: 'For you'), Tab(text: 'Products')],
          ),
        ),
        body: TabBarView(
          children: [
            FeedTab(profile: profile, repository: repo),
            ProductSearchTab(repository: repo),
          ],
        ),
      ),
    );
  }
}

class FeedTab extends StatelessWidget {
  const FeedTab({super.key, required this.profile, required this.repository});

  final HairProfile profile;
  final ContentRepository repository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ContentItem>>(
      future: repository.contentItems(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(child: Text('Could not load content.'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = ContentRanker.rank(snap.data!, profile);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Picked for ${profile.curlPattern} hair',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final item in items) _ContentCard(item: item),
            const SizedBox(height: 8),
            const Text(medicalDisclaimer, style: TextStyle(fontSize: 12)),
          ],
        );
      },
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.item});
  final ContentItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          item.type == ContentType.video
              ? Icons.play_circle_outline
              : Icons.article_outlined,
          color: AppColors.pink,
        ),
        title: Text(item.title),
        subtitle: Text(
          'Source: ${item.sourceName}'
          '${item.isMedicalSensitive ? '\n$medicalDisclaimer' : ''}',
        ),
        isThreeLine: item.isMedicalSensitive,
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: () => openSource(item.sourceUrl),
      ),
    );
  }
}

class ProductSearchTab extends StatefulWidget {
  const ProductSearchTab({super.key, required this.repository});
  final ContentRepository repository;

  @override
  State<ProductSearchTab> createState() => _ProductSearchTabState();
}

class _ProductSearchTabState extends State<ProductSearchTab> {
  late final Future<List<Product>> _products = widget.repository.products();
  String _query = '';

  static const _flagLabels = {
    IngredientFlag.sulfate: 'Sulfates',
    IngredientFlag.silicone: 'Silicones',
    IngredientFlag.dryingAlcohol: 'Drying alcohols',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search products or ingredients',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _products,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(child: Text('Could not load products.'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final matches = snap.data!.where((p) =>
                    _query.isEmpty ||
                    p.name.toLowerCase().contains(_query) ||
                    p.brand.toLowerCase().contains(_query) ||
                    p.ingredients.any((i) => i.toLowerCase().contains(_query)));
                return ListView(
                  children: [for (final p in matches) _productCard(p)],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard(Product p) {
    final flags = IngredientFlagger.flag(p.ingredients);
    return Card(
      child: ListTile(
        title: Text('${p.brand} — ${p.name}'),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 6,
            children: [
              if (flags.isEmpty)
                const Chip(label: Text('No flagged ingredients'))
              else
                for (final e in flags.entries)
                  Chip(
                    backgroundColor: AppColors.rose,
                    label: Text('${_flagLabels[e.key]}: ${e.value.join(', ')}'),
                  ),
            ],
          ),
        ),
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: () => openSource(p.sourceUrl),
      ),
    );
  }
}
