import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/content_item.dart';
import '../models/product.dart';
import 'local_content_repository.dart';

abstract class ContentRepository {
  Future<List<ContentItem>> contentItems();
  Future<List<Product>> products();

  /// Supabase when configured, bundled sample data otherwise (local mode).
  factory ContentRepository.create() => SupabaseConfig.isConfigured
      ? SupabaseContentRepository()
      : LocalContentRepository();
}

class SupabaseContentRepository implements ContentRepository {
  @override
  Future<List<ContentItem>> contentItems() async {
    final rows = await Supabase.instance.client.from('content_items').select();
    return rows.map(ContentItem.fromJson).toList();
  }

  @override
  Future<List<Product>> products() async {
    final rows = await Supabase.instance.client
        .from('products')
        .select('id, name, brand, source_url, product_ingredients(position, ingredients(name))');
    return rows.map((r) {
      final links = ((r['product_ingredients'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
        ..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));
      return Product(
        id: r['id'] as String,
        name: r['name'] as String,
        brand: r['brand'] as String,
        sourceUrl: r['source_url'] as String,
        ingredients: [
          for (final l in links) (l['ingredients'] as Map)['name'] as String,
        ],
      );
    }).toList();
  }
}
