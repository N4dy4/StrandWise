import 'package:flutter/material.dart';

import '../../models/hair_profile.dart';
import '../../models/wash_log.dart';
import '../../theme/app_theme.dart';

enum _ConditionChoice {
  rinseOut('Rinse-out'),
  deep('Deep'),
  both('Both');

  const _ConditionChoice(this.label);
  final String label;
}

/// Step-by-step wash day form. Pops with the finished [WashLog].
class LogWashScreen extends StatefulWidget {
  const LogWashScreen({super.key});

  @override
  State<LogWashScreen> createState() => _LogWashScreenState();
}

class _LogWashScreenState extends State<LogWashScreen> {
  static const _stepTitles = [
    'Before',
    'Pre-poo',
    'Cleanse',
    'Condition',
    'Style',
    'After',
    'Rate products',
  ];

  final _shampoo = TextEditingController();
  final _rinseOut = TextEditingController();
  final _deep = TextEditingController();
  final _style = TextEditingController();

  var _step = 0;
  HairFeel? _feelBefore;
  HairFeel? _feelAfter;
  final _styling = <HairStyling>{};
  var _prePoo = false;
  PrePooType? _prePooType;
  _ConditionChoice? _conditionChoice;
  final _ratings = <String, int>{};

  @override
  void dispose() {
    _shampoo.dispose();
    _rinseOut.dispose();
    _deep.dispose();
    _style.dispose();
    super.dispose();
  }

  bool get _needsRinseOut =>
      _conditionChoice == _ConditionChoice.rinseOut ||
      _conditionChoice == _ConditionChoice.both;
  bool get _needsDeep =>
      _conditionChoice == _ConditionChoice.deep ||
      _conditionChoice == _ConditionChoice.both;

  final _styleProducts = <String>[];

  void _addStyleProduct() {
    final name = _style.text.trim();
    if (name.isEmpty) return;
    setState(() {
      if (!_styleProducts.contains(name)) _styleProducts.add(name);
      _style.clear();
    });
  }

  /// Unique product names in the order they were used.
  List<String> get _products => {
    if (_shampoo.text.trim().isNotEmpty) _shampoo.text.trim(),
    if (_needsRinseOut && _rinseOut.text.trim().isNotEmpty)
      _rinseOut.text.trim(),
    if (_needsDeep && _deep.text.trim().isNotEmpty) _deep.text.trim(),
    ..._styleProducts,
  }.toList();

  bool get _canContinue => switch (_step) {
    0 => _feelBefore != null,
    1 => !_prePoo || _prePooType != null,
    2 => _shampoo.text.trim().isNotEmpty,
    3 =>
      _conditionChoice != null &&
          (!_needsRinseOut || _rinseOut.text.trim().isNotEmpty) &&
          (!_needsDeep || _deep.text.trim().isNotEmpty),
    5 => _feelAfter != null,
    _ => true,
  };

  void _next() {
    // Keep a product that was typed but not yet added with +.
    if (_step == 4) _addStyleProduct();
    if (_step < _stepTitles.length - 1) {
      setState(() => _step++);
    } else {
      _save();
    }
  }

  void _save() {
    final products = _products;
    Navigator.pop(
      context,
      WashLog(
        date: DateTime.now(),
        products: products,
        prePooType: _prePoo ? _prePooType : null,
        shampoo: _shampoo.text.trim(),
        rinseOutConditioner: _needsRinseOut ? _rinseOut.text.trim() : null,
        deepConditioner: _needsDeep ? _deep.text.trim() : null,
        styleProducts: _styleProducts,
        feelBefore: _feelBefore,
        feelAfter: _feelAfter,
        styling: {..._styling},
        ratings: {for (final p in products) p: _ratings[p] ?? 5},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final last = _step == _stepTitles.length - 1;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log wash day'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step ${_step + 1} of ${_stepTitles.length}',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_step + 1) / _stepTitles.length,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                  backgroundColor: AppColors.rose,
                  color: AppColors.pink,
                ),
                const SizedBox(height: 20),
                Text(
                  _stepTitles[_step],
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [_stepBody()],
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _step--),
                      child: const Text('Back'),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _canContinue ? _next : null,
                    child: Text(last ? 'Save wash day' : 'Continue'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBody() => switch (_step) {
    0 => _feelStep(
      'How did your hair feel before this wash day?',
      _feelBefore,
      (feel) => _feelBefore = feel,
    ),
    1 => _prePooStep(),
    2 => _cleanseStep(),
    3 => _conditionStep(),
    4 => _styleStep(),
    5 => _feelStep(
      'How does your hair feel after this wash day?',
      _feelAfter,
      (feel) => _feelAfter = feel,
    ),
    _ => _ratingStep(),
  };

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
  );

  Widget _feelStep(
    String question,
    HairFeel? selected,
    void Function(HairFeel feel) onSelect,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label(question),
      Wrap(
        spacing: 8,
        children: [
          for (final feel in HairFeel.values)
            ChoiceChip(
              label: Text(feel.label),
              selected: selected == feel,
              onSelected: (_) => setState(() => onSelect(feel)),
            ),
        ],
      ),
    ],
  );

  Widget _prePooStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label('Did you pre-poo?'),
      Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('Yes'),
            selected: _prePoo,
            onSelected: (_) => setState(() => _prePoo = true),
          ),
          ChoiceChip(
            label: const Text('No'),
            selected: !_prePoo,
            onSelected: (_) => setState(() {
              _prePoo = false;
              _prePooType = null;
            }),
          ),
        ],
      ),
      if (_prePoo) ...[
        const SizedBox(height: 20),
        _label('What type?'),
        Wrap(
          spacing: 8,
          children: [
            for (final type in PrePooType.values)
              ChoiceChip(
                label: Text(type.label),
                selected: _prePooType == type,
                onSelected: (_) => setState(() => _prePooType = type),
              ),
          ],
        ),
      ],
    ],
  );

  Widget _cleanseStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label('Which shampoo did you use?'),
      TextField(
        controller: _shampoo,
        decoration: const InputDecoration(labelText: 'Shampoo name'),
        textCapitalization: TextCapitalization.words,
        onChanged: (_) => setState(() {}),
      ),
    ],
  );

  Widget _conditionStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label('What type of conditioner?'),
      Wrap(
        spacing: 8,
        children: [
          for (final choice in _ConditionChoice.values)
            ChoiceChip(
              label: Text(choice.label),
              selected: _conditionChoice == choice,
              onSelected: (_) => setState(() => _conditionChoice = choice),
            ),
        ],
      ),
      if (_needsRinseOut) ...[
        const SizedBox(height: 20),
        TextField(
          controller: _rinseOut,
          decoration: const InputDecoration(
            labelText: 'Rinse-out conditioner name',
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),
      ],
      if (_needsDeep) ...[
        const SizedBox(height: 16),
        TextField(
          controller: _deep,
          decoration: const InputDecoration(labelText: 'Deep conditioner name'),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),
      ],
    ],
  );

  Widget _styleStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label('Add the products you styled with'),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _style,
              decoration: const InputDecoration(
                labelText: 'Style product',
                hintText: 'Leave-in, gel, oil…',
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addStyleProduct(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Add product',
            onPressed: _addStyleProduct,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      if (_styleProducts.isNotEmpty) ...[
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final product in _styleProducts)
              InputChip(
                label: Text(product),
                onDeleted: () => setState(() => _styleProducts.remove(product)),
              ),
          ],
        ),
      ],
      const SizedBox(height: 24),
      _label('How did you style your hair this wash day?'),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final styling in HairStyling.values)
            FilterChip(
              label: Text(styling.label),
              selected: _styling.contains(styling),
              onSelected: (on) => setState(
                () => on ? _styling.add(styling) : _styling.remove(styling),
              ),
            ),
        ],
      ),
    ],
  );

  Widget _ratingStep() {
    final products = _products;
    if (products.isEmpty) {
      return const Text(
        'No products to rate.',
        style: TextStyle(color: AppColors.muted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rate each product from 1 to 10.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        for (final product in products)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '${_ratings[product] ?? 5}/10',
                        style: const TextStyle(
                          color: AppColors.deepPink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: (_ratings[product] ?? 5).toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '${_ratings[product] ?? 5}',
                    semanticFormatterCallback: (value) =>
                        '$product rating ${value.round()} out of 10',
                    onChanged: (value) =>
                        setState(() => _ratings[product] = value.round()),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
