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
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
        children: [
          Text('Wash day', style: Theme.of(context).textTheme.headlineMedium),
          Text('Expert-built for your ${profile.curlPattern} hair.',
              style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 16),
          Card(
            color: AppColors.pink,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your personalized routine',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(routines.first.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(routines.first.frequency,
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final r in routines)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text(r.frequency, style: const TextStyle(color: AppColors.deepPink)),
                    const SizedBox(height: 8),
                    for (var i = 0; i < r.steps.length; i++)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.rose,
                          child: Text('${i + 1}', style: const TextStyle(color: AppColors.deepPink)),
                        ),
                        title: Text(r.steps[i].title),
                        subtitle: Text(r.steps[i].detail),
                      ),
                  ],
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
            'General guidance, not medical advice. For hair loss or scalp conditions, see a doctor or dermatologist.',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
