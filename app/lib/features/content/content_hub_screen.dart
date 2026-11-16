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
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Learn'),
          centerTitle: false,
          toolbarHeight: 72,
          titleTextStyle: Theme.of(context).textTheme.headlineMedium,
          bottom: const TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: 'For you'),
              Tab(text: 'Ask anything'),
              Tab(text: 'Products'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            FeedTab(profile: profile, repository: repo),
            const AskAnythingTab(),
            ProductSearchTab(repository: repo),
          ],
        ),
      ),
    );
  }
}

class AskAnythingTab extends StatelessWidget {
  const AskAnythingTab({super.key});

  static const _sources = [
    ('American Academy of Dermatology', 'https://www.aad.org/'),
    ('PubMed', 'https://pubmed.ncbi.nlm.nih.gov/'),
    ('NaturallyCurly', 'https://www.naturallycurly.com/'),
  ];

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const TextField(
        decoration: InputDecoration(
          hintText: 'Is rice water good for my hair?',
          prefixIcon: Icon(Icons.search),
        ),
      ),
      const SizedBox(height: 16),
      const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text(
            'Rice water may add temporary strength, but evidence is limited. '
            'Overuse can leave some hair feeling dry or stiff. Try a patch '
            'test and stop if your hair becomes brittle.',
            style: TextStyle(height: 1.45),
          ),
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'SOURCES',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 8),
      for (final source in _sources)
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.pink,
              child: Icon(Icons.link, color: Colors.white, size: 18),
            ),
            title: Text(source.$1),
            subtitle: Text(Uri.parse(source.$2).host),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => openSource(source.$2),
          ),
        ),
      const SizedBox(height: 8),
      const Text(medicalDisclaimer, style: TextStyle(fontSize: 12)),
    ],
  );
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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Text(
              'Picked for your ${profile.curlPattern} hair',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            const Text(
              'Practical guidance from cited sources.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
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
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => openSource(item.sourceUrl),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.rose,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.type == ContentType.video
                      ? Icons.play_arrow_rounded
                      : Icons.article_outlined,
                  color: AppColors.deepPink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Source: ${item.sourceName}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                    if (item.isMedicalSensitive)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          medicalDisclaimer,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new, size: 18, color: AppColors.muted),
            ],
          ),
        ),
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
      padding: const EdgeInsets.all(20),
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
                final matches = snap.data!.where(
                  (p) =>
                      _query.isEmpty ||
                      p.name.toLowerCase().contains(_query) ||
                      p.brand.toLowerCase().contains(_query) ||
                      p.ingredients.any(
                        (i) => i.toLowerCase().contains(_query),
                      ),
                );
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (p.description.isNotEmpty) ...[
                Text(
                  p.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              Wrap(
                spacing: 6,
                children: [
                  for (final pattern in p.curlPatterns)
                    Chip(label: Text('Type $pattern hair')),
                  if (p.ingredients.isEmpty)
                    const Chip(label: Text('Ingredients not listed yet'))
                  else if (flags.isEmpty)
                    const Chip(label: Text('No flagged ingredients'))
                  else
                    for (final e in flags.entries)
                      Chip(
                        backgroundColor: AppColors.rose,
                        label: Text(
                          '${_flagLabels[e.key]}: ${e.value.join(', ')}',
                        ),
                      ),
                ],
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: 'Product options',
          onSelected: (action) {
            if (action == 'ingredients') {
              showIngredientCheck(context, p);
            } else {
              openSource(p.sourceUrl);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'ingredients',
              child: Text('Check ingredients'),
            ),
            PopupMenuItem(value: 'source', child: Text('View source')),
          ],
        ),
        onTap: () => showIngredientCheck(context, p),
      ),
    );
  }
}

/// Ingredient check for [product]: every ingredient in label order, with
/// sulfates, silicones and drying alcohols highlighted, plus the citation.
Future<void> showIngredientCheck(BuildContext context, Product product) {
  const flagLabels = {
    IngredientFlag.sulfate: 'Sulfate',
    IngredientFlag.silicone: 'Silicone',
    IngredientFlag.dryingAlcohol: 'Drying alcohol',
  };
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(
            '${product.brand} — ${product.name}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          const Text('Ingredient check'),
          const SizedBox(height: 12),
          if (product.ingredients.isEmpty)
            const Text(
              'We could not read this product\'s ingredient list yet. '
              'Check the brand\'s page for the full label.',
            )
          else
            for (final (i, name) in product.ingredients.indexed)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Text('${i + 1}.'),
                title: Text(name),
                trailing: IngredientFlagger.flagFor(name) == null
                    ? null
                    : Chip(
                        backgroundColor: AppColors.rose,
                        label: Text(
                          flagLabels[IngredientFlagger.flagFor(name)]!,
                        ),
                      ),
              ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => openSource(product.sourceUrl),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('View source'),
          ),
          const Text(medicalDisclaimer, style: TextStyle(fontSize: 12)),
        ],
      ),
    ),
  );
}
