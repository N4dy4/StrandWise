import 'dart:convert';

enum PrePooType {
  oil('Oil'),
  conditioner('Conditioner'),
  mask('Mask'),
  other('Other');

  const PrePooType(this.label);
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
  );

  String encode() => jsonEncode(toJson());
}
