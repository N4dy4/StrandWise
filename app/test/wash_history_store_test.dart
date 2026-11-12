import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strandwise/data/wash_history_store.dart';
import 'package:strandwise/models/wash_log.dart';

void main() {
  test(
    'saves products for a wash day and replaces that day when updated',
    () async {
      SharedPreferences.setMockInitialValues({});
      final day = DateTime(2026, 11, 10);

      await WashHistoryStore.save(
        WashLog(date: day, products: const ['Cleanser']),
      );
      await WashHistoryStore.save(
        WashLog(date: day, products: const ['Cleanser', 'Conditioner']),
      );

      final logs = await WashHistoryStore.load();
      expect(logs, hasLength(1));
      expect(logs.single.products, ['Cleanser', 'Conditioner']);
    },
  );
}
