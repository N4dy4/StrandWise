import 'dart:convert';

import 'hair_profile.dart';

enum PrePooType {
  oil('Oil'),
  conditioner('Conditioner'),
  mask('Mask'),
  other('Other');

  const PrePooType(this.label);
  final String label;
}

enum HairFeel {
  dry('Dry'),
  normal('Normal'),
  oily('Oily');

  const HairFeel(this.label);
  final String label;
}

class WashLog {
  const WashLog({
    required this.date,
    required this.products,
    this.prePooType,
    this.shampoo,
    this.rinseOutConditioner,
    this.deepConditioner,
    this.styleProducts = const [],
    this.ratings = const {},
    this.feelBefore,
    this.feelAfter,
    this.styling = const {},
  });

  final DateTime date;

  /// Every product used on wash day; keys of [ratings] come from this list.
  final List<String> products;

  /// Null means no pre-poo was done.
  final PrePooType? prePooType;
  final String? shampoo;
  final String? rinseOutConditioner;
  final String? deepConditioner;
  final List<String> styleProducts;

  /// Product name -> rating from 1 to 10.
  final Map<String, int> ratings;

  /// How the hair felt before and after this wash; null on older logs.
  final HairFeel? feelBefore;
  final HairFeel? feelAfter;

  /// How the hair was styled after this wash.
  final Set<HairStyling> styling;

  bool get didPrePoo => prePooType != null;

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'products': products,
    'prePooType': prePooType?.name,
    'shampoo': shampoo,
    'rinseOutConditioner': rinseOutConditioner,
    'deepConditioner': deepConditioner,
    'styleProducts': styleProducts,
    'ratings': ratings,
    'feelBefore': feelBefore?.name,
    'feelAfter': feelAfter?.name,
    'styling': styling.map((s) => s.name).toList(),
  };

  factory WashLog.fromJson(Map<String, dynamic> json) => WashLog(
    date: DateTime.parse(json['date'] as String),
    products: (json['products'] as List)
        .map((product) => product as String)
        .toList(),
    prePooType: switch (json['prePooType']) {
      final String name => PrePooType.values.byName(name),
      _ => null,
    },
    shampoo: json['shampoo'] as String?,
    rinseOutConditioner: json['rinseOutConditioner'] as String?,
    deepConditioner: json['deepConditioner'] as String?,
    styleProducts: ((json['styleProducts'] as List?) ?? const [])
        .map((product) => product as String)
        .toList(),
    ratings: {
      for (final entry in ((json['ratings'] as Map?) ?? const {}).entries)
        entry.key as String: entry.value as int,
    },
    feelBefore: _feel(json['feelBefore']),
    feelAfter: _feel(json['feelAfter']),
    styling: {
      for (final name in (json['styling'] as List? ?? const []))
        for (final s in HairStyling.values)
          if (s.name == name) s,
    },
  );

  static HairFeel? _feel(Object? name) {
    for (final f in HairFeel.values) {
      if (f.name == name) return f;
    }
    return null;
  }

  String encode() => jsonEncode(toJson());
}
