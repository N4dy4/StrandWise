import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/content_repository.dart';
import '../../models/content_item.dart';
import '../../models/hair_profile.dart';
import '../../models/ingredient_info.dart';
import '../../models/product.dart';
import '../../services/ai_assistant.dart';
import '../../services/content_ranker.dart';
import '../../services/ingredient_flagger.dart';
import '../../theme/app_theme.dart';

const medicalDisclaimer =
    'Not medical advice. For hair loss or scalp conditions, see a doctor or dermatologist.';

Future<void> openSource(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

class ContentHubScreen extends StatelessWidget {
  const ContentHubScreen({
    super.key,
    required this.profile,
    this.repository,
    this.assistant,
  });

  final HairProfile profile;
  final ContentRepository? repository;
  final AiAssistant? assistant;

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
            AskAnythingTab(profile: profile, assistant: assistant),
            ProductSearchTab(repository: repo),
          ],
        ),
      ),
    );
  }
}

class AskAnythingTab extends StatefulWidget {
  const AskAnythingTab({super.key, required this.profile, this.assistant});

  final HairProfile profile;
  final AiAssistant? assistant;

  @override
  State<AskAnythingTab> createState() => _AskAnythingTabState();
}

class _AskAnythingTabState extends State<AskAnythingTab> {
  static const _sources = [
    ('American Academy of Dermatology', 'https://www.aad.org/'),
    ('PubMed', 'https://pubmed.ncbi.nlm.nih.gov/'),
    ('NaturallyCurly', 'https://www.naturallycurly.com/'),
  ];

  late final AiAssistant _assistant = widget.assistant ?? AiAssistant.create();
  final _controller = TextEditingController();
  AiAnswer? _answer;
  var _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final question = _controller.text.trim();
    if (question.isEmpty || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final answer = await _assistant.ask(question, widget.profile);
      if (!mounted) return;
      setState(() => _answer = answer);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = _assistant.isAvailable
            ? 'Could not get an answer. Try again in a moment.'
            : 'AI answers need a Supabase connection (local mode is on).',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: 'Is rice water good for my hair?',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _loading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  tooltip: 'Ask',
                  icon: const Icon(Icons.send),
                  onPressed: _submit,
                ),
        ),
      ),
      const SizedBox(height: 16),
      if (_error != null)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Text(_error!, style: const TextStyle(height: 1.45)),
          ),
        ),
      if (_answer != null) ...[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.pink, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'AI answer',
                      style: TextStyle(
                        color: AppColors.deepPink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(_answer!.text, style: const TextStyle(height: 1.45)),
              ],
            ),
          ),
        ),
        for (final p in _answer!.products)
          Card(
            margin: const EdgeInsets.only(top: 8),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.pink,
                child: Icon(Icons.shopping_bag, color: Colors.white, size: 18),
              ),
              title: Text(p.name),
              subtitle: Text('${p.brand} · ${Uri.parse(p.sourceUrl).host}'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => openSource(p.sourceUrl),
            ),
          ),
      ] else if (_error == null)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Text(
              'Ask about routines, ingredients or products. Answers use your '
              'hair profile. Try: "What should I use for dry 4C hair?"',
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

enum FeedFilter {
  all('All'),
  videos('Videos'),
  youtube('YouTube'),
  tiktok('TikTok'),
  articles('Articles');

  const FeedFilter(this.label);
  final String label;

  bool matches(ContentItem i) => switch (this) {
    all => true,
    videos => i.type == ContentType.video,
    youtube => i.platform == ContentPlatform.youtube,
    tiktok => i.platform == ContentPlatform.tiktok,
    articles => i.type == ContentType.article,
  };
}

class FeedTab extends StatefulWidget {
  const FeedTab({super.key, required this.profile, required this.repository});

  final HairProfile profile;
  final ContentRepository repository;

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  late final Future<List<ContentItem>> _future = widget.repository
      .contentItems();
  FeedFilter _filter = FeedFilter.all;

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    return FutureBuilder<List<ContentItem>>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(child: Text('Could not load content.'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final ranked = ContentRanker.rank(snap.data!, profile);
        final items = ranked.where(_filter.matches).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Text(
              'For you · ${profile.curlPattern} hair',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            const Text(
              'Practical guidance from cited sources.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final f in FeedFilter.values)
                  ChoiceChip(
                    label: Text(f.label),
                    selected: _filter == f,
                    selectedColor: AppColors.rose,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Nothing here yet — try another filter.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              ),
            for (final item in items)
              _ContentCard(
                item: item,
                reason: ContentRanker.reason(item, profile),
              ),
            const SizedBox(height: 8),
            const Text(medicalDisclaimer, style: TextStyle(fontSize: 12)),
          ],
        );
      },
    );
  }
}

String _platformLabel(ContentItem i) => switch (i.platform) {
  ContentPlatform.youtube => 'YouTube',
  ContentPlatform.tiktok => 'TikTok',
  ContentPlatform.web => i.type == ContentType.video ? 'Video' : 'Article',
};

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.item, this.reason});
  final ContentItem item;
  final String? reason;

  Widget _iconFallback() => Container(
    width: 56,
    height: 56,
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
  );

  Widget _leading() {
    if (item.thumbnailUrl.isEmpty) return _iconFallback();
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
      child: Image.network(
        item.thumbnailUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _iconFallback(),
      ),
    );
  }

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
              _leading(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.rose,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _platformLabel(item),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepPink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (reason != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        reason!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.deepPink,
                        ),
                      ),
                    ],
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
              showIngredientCheck(context, p, widget.repository);
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
        onTap: () => showIngredientCheck(context, p, widget.repository),
      ),
    );
  }
}

/// Ingredient check for [product]: every ingredient in label order, with
/// sulfates, silicones and drying alcohols highlighted, plus the citation.
Future<void> showIngredientCheck(
  BuildContext context,
  Product product,
  ContentRepository repository,
) {
  final info = repository.ingredientInfo().catchError(
    (_) => <String, IngredientInfo>{},
  );
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
      builder: (context, controller) =>
          FutureBuilder<Map<String, IngredientInfo>>(
            future: info,
            builder: (context, snap) {
              final infoByName = snap.data ?? const <String, IngredientInfo>{};
              return ListView(
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
                      _ingredientTile(
                        i + 1,
                        name,
                        infoByName[name.toLowerCase()],
                        flagLabels,
                      ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => openSource(product.sourceUrl),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('View source'),
                  ),
                  const Text(medicalDisclaimer, style: TextStyle(fontSize: 12)),
                ],
              );
            },
          ),
    ),
  );
}

Widget _ingredientTile(
  int position,
  String name,
  IngredientInfo? info,
  Map<IngredientFlag, String> flagLabels,
) {
  final flag = IngredientFlagger.flagFor(name);
  final flagChip = flag == null
      ? null
      : Chip(backgroundColor: AppColors.rose, label: Text(flagLabels[flag]!));
  if (info == null) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Text('$position.'),
      title: Text(name),
      trailing: flagChip,
    );
  }
  Widget section(String label, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(text),
      ],
    ),
  );
  return ExpansionTile(
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(left: 24, bottom: 8),
    expandedCrossAxisAlignment: CrossAxisAlignment.start,
    leading: Text('$position.'),
    title: Text(name),
    subtitle: const Text('Tap to learn more'),
    trailing: flagChip,
    children: [
      section('What it is', info.whatItIs),
      section('Why it\'s used in hair care', info.whyUsed),
      section('Benefits & risks for hair', info.hairEffects),
      TextButton.icon(
        onPressed: () => openSource(info.sourceUrl),
        icon: const Icon(Icons.open_in_new, size: 16),
        label: const Text('Source'),
      ),
    ],
  );
}
