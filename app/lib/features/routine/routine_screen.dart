import 'package:flutter/material.dart';

import '../../models/hair_profile.dart';
import '../../services/routine_engine.dart';
import '../../theme/app_theme.dart';

class RoutineScreen extends StatelessWidget {
  const RoutineScreen({super.key, required this.profile});
  final HairProfile profile;

  @override
  Widget build(BuildContext context) {
    final routines = RoutineEngine.build(profile);
    final routine = routines.first;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Wash day, Sunday',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ),
              const _OfflineBadge(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your ${profile.curlPattern} hair needs moisture today',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Card(
            color: AppColors.pink,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 15),
                      SizedBox(width: 6),
                      Text(
                        'Personalized by your hair profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    routine.name,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Based on ${profile.curlPattern} hair, '
                    '${profile.porosity.name} porosity',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  const LinearProgressIndicator(
                    value: .5,
                    minHeight: 6,
                    borderRadius: BorderRadius.all(Radius.circular(3)),
                    backgroundColor: Color(0x55FFFFFF),
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < routine.steps.length; index++)
            _RoutineStepCard(
              title: routine.steps[index].title,
              detail: routine.steps[index].detail,
              completed: index < 2,
            ),
          const SizedBox(height: 4),
          const Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.rose,
                child: Icon(Icons.notifications_none, color: AppColors.pink),
              ),
              title: Text(
                'Deep condition at 6:30 pm',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('Reminder works without a connection'),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              'General guidance, not medical advice. For hair loss or scalp '
              'conditions, see a doctor or dermatologist.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.rose,
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_off_outlined, size: 14, color: AppColors.pink),
        SizedBox(width: 4),
        Text(
          'Offline, saved on device',
          style: TextStyle(
            color: AppColors.pink,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _RoutineStepCard extends StatelessWidget {
  const _RoutineStepCard({
    required this.title,
    required this.detail,
    required this.completed,
  });

  final String title;
  final String detail;
  final bool completed;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: completed ? AppColors.pink : AppColors.rose,
        child: Icon(
          completed ? Icons.check : Icons.water_drop_outlined,
          color: completed ? Colors.white : AppColors.muted,
          size: 18,
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(detail),
    ),
  );
}
