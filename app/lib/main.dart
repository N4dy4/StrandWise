import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'features/content/content_hub_screen.dart';
import 'data/profile_store.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/routine/routine_screen.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HairProfile? profile;

  @override
  void initState() {
    super.initState();
    ProfileStore.load().then((p) {
      if (mounted) setState(() => profile = p);
    }).catchError((_) {});
  }

  void _open(BuildContext context, Widget screen) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => screen));

  void _quiz(BuildContext context) => _open(
        context,
        OnboardingScreen(
          initial: profile,
          onDone: (p) {
            setState(() => profile = p);
            Navigator.of(context).pop();
          },
        ),
      );

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
                if (profile == null)
                  FilledButton(
                    onPressed: () => _quiz(context),
                    child: const Text('Take the hair quiz'),
                  )
                else ...[
                  Text('Your hair: ${profile!.curlPattern}'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => _open(
                        context, RoutineScreen(profile: profile!)),
                    child: const Text('My routine'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => _open(
                        context, ContentHubScreen(profile: profile!)),
                    child: const Text('Discover'),
                  ),
                  TextButton(
                    onPressed: () => _quiz(context),
                    child: const Text('Retake quiz'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
