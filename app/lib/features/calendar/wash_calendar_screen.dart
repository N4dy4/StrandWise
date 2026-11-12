import 'package:flutter/material.dart';

import '../../data/wash_history_store.dart';
import '../../models/hair_profile.dart';
import '../../models/wash_log.dart';
import '../../services/routine_engine.dart';
import '../../theme/app_theme.dart';
import 'log_wash_screen.dart';

class WashCalendarScreen extends StatefulWidget {
  const WashCalendarScreen({super.key, required this.profile});

  final HairProfile profile;

  @override
  State<WashCalendarScreen> createState() => _WashCalendarScreenState();
}

class _WashCalendarScreenState extends State<WashCalendarScreen> {
  List<WashLog> _washLogs = [];
  var _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final logs = await WashHistoryStore.load();
    if (mounted) {
      setState(() {
        _washLogs = logs;
        _loadingHistory = false;
      });
    }
  }

  Future<void> _logWashDay() async {
    final log = await Navigator.of(
      context,
    ).push<WashLog>(MaterialPageRoute(builder: (_) => const LogWashScreen()));

    if (log == null) return;
    await WashHistoryStore.save(log);
    await _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final nextWash = RoutineEngine.nextWashDate(
      widget.profile,
      _washLogs.isEmpty ? DateTime.now() : _washLogs.first.date,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Wash calendar'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            'Plan your next wash day',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Your ${RoutineEngine.washFrequency(widget.profile).toLowerCase()} schedule adapts to your hair profile.',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          _Calendar(
            logs: _washLogs,
            loading: _loadingHistory,
            nextWash: nextWash,
            onLogWash: _logWashDay,
          ),
        ],
      ),
    );
  }
}

class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.logs,
    required this.loading,
    required this.nextWash,
    required this.onLogWash,
  });

  final List<WashLog> logs;
  final bool loading;
  final DateTime nextWash;
  final VoidCallback onLogWash;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final washDays = {for (final log in logs) _dayKey(log.date): log};
    final firstDay = DateTime(today.year, today.month);
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
    final leadingDays = firstDay.weekday % 7;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Next recommended wash: ${_monthDay(nextWash)}'),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _WeekdayLabel('S'),
                _WeekdayLabel('M'),
                _WeekdayLabel('T'),
                _WeekdayLabel('W'),
                _WeekdayLabel('T'),
                _WeekdayLabel('F'),
                _WeekdayLabel('S'),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: leadingDays + daysInMonth,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                if (index < leadingDays) return const SizedBox();
                final day = index - leadingDays + 1;
                final date = DateTime(today.year, today.month, day);
                final log = washDays[_dayKey(date)];
                final isRecommended = _sameDay(date, nextWash);
                final isToday = _sameDay(date, today);
                return Tooltip(
                  message: log == null
                      ? (isRecommended ? 'Recommended wash day' : '')
                      : 'Wash day: ${_summary(log)}',
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: log != null
                          ? AppColors.pink
                          : isRecommended
                          ? AppColors.rose
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        AppTheme.cornerRadius,
                      ),
                      border: isToday
                          ? Border.all(color: AppColors.deepPink)
                          : null,
                    ),
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: log != null ? Colors.white : AppColors.ink,
                        fontWeight: log != null || isRecommended
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (logs.isEmpty)
              const Text(
                'Log a wash day to start your history.',
                style: TextStyle(color: AppColors.muted),
              )
            else
              ...logs
                  .take(3)
                  .map(
                    (log) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${_monthDay(log.date)} · ${_summary(log)}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onLogWash,
                icon: const Icon(Icons.add),
                label: const Text('Log today’s wash'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: AppColors.muted,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
  );
}

String _summary(WashLog log) {
  final products = log.products.isEmpty
      ? 'No products added'
      : log.products
            .map(
              (product) => log.ratings[product] == null
                  ? product
                  : '$product (${log.ratings[product]}/10)',
            )
            .join(', ');
  final prePoo = log.prePooType == null
      ? 'No pre-poo'
      : 'Pre-poo: ${log.prePooType!.label}';
  return '$prePoo · $products';
}

bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

String _dayKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String _monthDay(DateTime date) =>
    '${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1]} ${date.day}';
