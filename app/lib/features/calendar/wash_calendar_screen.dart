import 'package:flutter/material.dart';

import '../../data/wash_history_store.dart';
import '../../models/hair_profile.dart';
import '../../models/wash_log.dart';
import '../../services/routine_engine.dart';
import '../../services/wash_insights.dart';
import '../../theme/app_theme.dart';
import '../../widgets/strand_motion.dart';
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        content: Row(
          children: [
            PopBadge(size: 36),
            SizedBox(width: 12),
            Text('Wash day logged'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final insights = WashInsightsEngine.analyze(widget.profile, _washLogs);
    final last = _washLogs.isEmpty ? DateTime.now() : _washLogs.first.date;
    final nextWash = DateTime(
      last.year,
      last.month,
      last.day,
    ).add(Duration(days: insights.intervalDays));

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
          const SizedBox(height: 16),
          InsightsCard(insights: insights),
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

class InsightsCard extends StatelessWidget {
  const InsightsCard({super.key, required this.insights});

  final WashInsights insights;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Smart suggestions',
              style: TextStyle(
                color: AppColors.deepPink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text('Your wash-day insights', style: titleStyle),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.blush,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
              ),
              child: Text(
                insights.summary,
                style: const TextStyle(color: AppColors.ink, height: 1.4),
              ),
            ),
            if (insights.scheduleNote.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                insights.scheduleNote,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
            if (insights.washDayPlan.isNotEmpty)
              _InsightSection(
                title: 'Your wash-day plan',
                icon: Icons.water_drop_outlined,
                items: insights.washDayPlan,
                numbered: true,
                initiallyExpanded: true,
              ),
            if (insights.practices.isNotEmpty)
              _InsightSection(
                title: 'Practices to try',
                icon: Icons.favorite_border,
                items: insights.practices,
                initiallyExpanded: true,
              ),
            if (insights.productTips.isNotEmpty)
              _InsightSection(
                title: 'Products to look for',
                icon: Icons.search,
                items: insights.productTips,
              ),
            if (insights.avoid.isNotEmpty)
              _InsightSection(
                title: 'Go easy on',
                icon: Icons.spa_outlined,
                items: insights.avoid,
              ),
            if (insights.productFeedback.isNotEmpty)
              _InsightSection(
                title: 'From your logs',
                icon: Icons.edit_note,
                items: insights.productFeedback,
              ),
            const SizedBox(height: 12),
            const Text(
              'Not medical advice. See a doctor or dermatologist about hair loss or scalp concerns.',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightSection extends StatelessWidget {
  const _InsightSection({
    required this.title,
    required this.icon,
    required this.items,
    this.numbered = false,
    this.initiallyExpanded = false,
  });

  final String title;
  final IconData icon;
  final List<String> items;
  final bool numbered;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: AppColors.deepPink,
          collapsedIconColor: AppColors.pink,
          backgroundColor: AppColors.blush,
          collapsedBackgroundColor: AppColors.blush,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
          ),
          leading: Icon(icon, color: AppColors.pink, size: 20),
          title: Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          children: [
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (numbered)
                      Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(right: 10, top: 1),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.rose,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: AppColors.deepPink,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.only(right: 10, top: 1),
                        child: Icon(
                          Icons.circle,
                          size: 7,
                          color: AppColors.pink,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        items[i],
                        style: const TextStyle(
                          color: AppColors.ink,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
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
  final feel = log.feelBefore == null && log.feelAfter == null
      ? ''
      : ' · Feel: ${log.feelBefore?.label ?? '—'} → ${log.feelAfter?.label ?? '—'}';
  final styling = log.styling.isEmpty
      ? ''
      : ' · Styling: ${log.styling.map((s) => s.label).join(', ')}';
  return '$prePoo · $products$feel$styling';
}

bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

String _dayKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String _monthDay(DateTime date) =>
    '${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1]} ${date.day}';
