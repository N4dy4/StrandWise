import 'package:shared_preferences/shared_preferences.dart';

import '../models/hair_profile.dart';

/// Offline-first local storage (R3). Hair data never leaves the device here (R4).
class ProfileStore {
  static const _key = 'hair_profile';

  static Future<HairProfile?> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw == null) return null;
    try {
      return HairProfile.decode(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(HairProfile p) async =>
      (await SharedPreferences.getInstance()).setString(_key, p.encode());

  static Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(_key);
}
