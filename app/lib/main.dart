import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'features/content/content_hub_screen.dart';
import 'models/hair_profile.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  }

  runApp(const StrandWiseApp());
}

class StrandWiseApp extends StatelessWidget {
  const StrandWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StrandWise',
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('StrandWise')),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome to StrandWise',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  SupabaseConfig.isConfigured
                      ? 'Connected to Supabase.'
                      : 'Running locally — Supabase not configured yet.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      // Placeholder until the Phase 1 onboarding quiz exists.
                      builder: (_) => const ContentHubScreen(
                        profile: HairProfile(curlPattern: '3B'),
                      ),
                    ),
                  ),
                  child: const Text('Discover'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
