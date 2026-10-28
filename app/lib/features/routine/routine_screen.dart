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
      appBar: AppBar(title: const Text('Your routine')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Expert-built for ${profile.curlPattern} hair',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final r in routines)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text(r.frequency,
                        style: const TextStyle(color: AppColors.deepPink)),
                    const SizedBox(height: 8),
                    for (var i = 0; i < r.steps.length; i++)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.rose,
                          child: Text('${i + 1}'),
                        ),
                        title: Text(r.steps[i].title),
                        subtitle: Text(r.steps[i].detail),
                      ),
                  ],
                ),
              ),
            ),
          const Text(
            'General guidance, not medical advice. For hair loss or scalp conditions, see a doctor or dermatologist.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
