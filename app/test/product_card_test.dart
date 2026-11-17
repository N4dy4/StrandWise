import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strandwise/data/local_content_repository.dart';
import 'package:strandwise/features/content/content_hub_screen.dart';
import 'package:strandwise/models/ingredient_info.dart';
import 'package:strandwise/models/product.dart';
import 'package:strandwise/theme/app_theme.dart';

class _Repo extends LocalContentRepository {
  @override
  Future<List<Product>> products() async => const [
    Product(
      id: 'x',
      name: 'Test Shampoo',
      brand: 'Brand',
      description: 'A gentle cleansing shampoo.',
      sourceUrl: 'https://example.com/p/test',
      ingredients: [
        'Water',
        'Sodium Lauryl Sulfate',
        'Dimethicone',
        'Glycerin',
      ],
    ),
  ];

  @override
  Future<Map<String, IngredientInfo>> ingredientInfo() async => const {
    'glycerin': IngredientInfo(
      whatItIs: 'A clear, sweet liquid humectant.',
      whyUsed: 'Draws water into hair.',
      hairEffects: 'Can hydrate; may cause frizz in very dry air.',
      sourceUrl: 'https://example.com/glycerin',
    ),
  };
}

void main() {
  testWidgets('product card shows description; dots open ingredient check', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: ProductSearchTab(repository: _Repo())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('A gentle cleansing shampoo.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check ingredients'));
    await tester.pumpAndSettle();

    expect(find.text('Ingredient check'), findsOneWidget);
    expect(find.text('Sodium Lauryl Sulfate'), findsOneWidget);
    expect(find.text('Sulfate'), findsOneWidget);
    expect(find.text('Silicone'), findsOneWidget);

    await tester.tap(find.text('Glycerin'));
    await tester.pumpAndSettle();
    expect(find.text('What it is'), findsOneWidget);
    expect(find.text('Benefits & risks for hair'), findsOneWidget);
  });
}
