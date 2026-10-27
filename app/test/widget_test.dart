import 'package:flutter_test/flutter_test.dart';

import 'package:strandwise/main.dart';
import 'package:strandwise/theme/app_theme.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const StrandWiseApp());

    expect(find.text('StrandWise'), findsOneWidget);
    expect(find.text('Welcome to StrandWise'), findsOneWidget);
  });

  test('Theme uses pink primary color (R1)', () {
    expect(AppTheme.light.colorScheme.primary, AppColors.pink);
    expect(AppTheme.light.scaffoldBackgroundColor, AppColors.blush);
  });
}
