import '../models/content_item.dart';
import '../models/hair_profile.dart';
import '../models/product.dart';
import 'content_repository.dart';

/// Bundled SAMPLE data so the app works without Supabase. Source URLs point
/// at publisher sites; replace with curated, validated links before launch.
class LocalContentRepository implements ContentRepository {
  @override
  Future<List<ContentItem>> contentItems() async => const [
        ContentItem(
          id: 'c1',
          type: ContentType.article,
          title: 'Curly hair care basics',
          sourceName: 'NaturallyCurly',
          sourceUrl: 'https://www.naturallycurly.com/',
          curlPatterns: {'2', '3', '4'},
        ),
        ContentItem(
          id: 'c2',
          type: ContentType.article,
          title: 'Managing breakage on coily hair',
          sourceName: 'NaturallyCurly',
          sourceUrl: 'https://www.naturallycurly.com/',
          curlPatterns: {'4'},
          concerns: {HairConcern.breakage},
        ),
        ContentItem(
          id: 'c3',
          type: ContentType.article,
          title: 'Dandruff and your scalp',
          sourceName: 'American Academy of Dermatology',
          sourceUrl: 'https://www.aad.org/',
          concerns: {HairConcern.dandruff},
        ),
        ContentItem(
          id: 'c4',
          type: ContentType.video,
          title: 'Taming frizz on wavy hair',
          sourceName: 'YouTube',
          sourceUrl: 'https://www.youtube.com/',
          curlPatterns: {'2'},
          concerns: {HairConcern.frizz},
        ),
      ];

  @override
  Future<List<Product>> products() async => const [
        Product(
          id: 'p1',
          name: 'Sample Clarifying Shampoo',
          brand: 'Example Brand',
          sourceUrl: 'https://www.example.com/',
          ingredients: [
            'Water',
            'Sodium Lauryl Sulfate',
            'Dimethicone',
            'Alcohol Denat.',
            'Cetyl Alcohol',
          ],
        ),
        Product(
          id: 'p2',
          name: 'Sample Moisture Conditioner',
          brand: 'Example Brand',
          sourceUrl: 'https://www.example.com/',
          ingredients: ['Water', 'Cetearyl Alcohol', 'Shea Butter', 'Glycerin'],
        ),
      ];
}
