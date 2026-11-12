import 'package:flutter/material.dart';

import '../../models/hair_profile.dart';
import '../../services/routine_engine.dart';
import '../../theme/app_theme.dart';

class RoutineScreen extends StatelessWidget {
  const RoutineScreen({super.key, required this.profile});

  final HairProfile profile;

  @override
  Widget build(BuildContext context) {
    final routine = RoutineEngine.washDay(profile);
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
        children: [
          Text(
            'Your ${profile.curlPattern} hair routine',
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
                  const Text(
                    'Personalized by your hair profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    routine.name,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${routine.frequency} · ${profile.porosity.name} porosity',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final step in routine.steps)
            _RoutineStepCard(title: step.title, detail: step.detail),
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

class _RoutineStepCard extends StatelessWidget {
  const _RoutineStepCard({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: const CircleAvatar(
        backgroundColor: AppColors.rose,
        child: Icon(
          Icons.water_drop_outlined,
          color: AppColors.muted,
          size: 18,
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(detail),
    ),
  );
}
