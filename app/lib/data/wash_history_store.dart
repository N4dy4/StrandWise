import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/wash_log.dart';

/// Stores wash history locally so the calendar remains useful offline.
class WashHistoryStore {
  static const _key = 'wash_history';

  static Future<List<WashLog>> load() async {
    final raw = (await SharedPreferences.getInstance()).getStringList(_key);
    if (raw == null) return [];

    final logs = <WashLog>[];
    for (final entry in raw) {
      try {
        logs.add(WashLog.fromJson(jsonDecode(entry) as Map<String, dynamic>));
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      }
    }
    logs.sort((a, b) => b.date.compareTo(a.date));
    return logs;
  }

  static Future<void> save(WashLog log) async {
    final logs = await load();
    logs.removeWhere((existing) => _sameDay(existing.date, log.date));
    logs.add(log);
    logs.sort((a, b) => b.date.compareTo(a.date));
    await (await SharedPreferences.getInstance()).setStringList(
      _key,
      logs.map((entry) => entry.encode()).toList(),
    );
  }

  static bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
