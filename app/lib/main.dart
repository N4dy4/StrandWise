import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'data/profile_store.dart';
import 'features/home/app_shell.dart';
import 'features/onboarding/disclaimer_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'models/hair_profile.dart';
import 'theme/app_theme.dart';
import 'widgets/strandwise_logo.dart';

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

  void _editProfile(BuildContext context) => _open(
        context,
        OnboardingScreen(
          initial: profile,
          onDone: (p) {
            setState(() => profile = p);
            Navigator.of(context).pop();
          },
        ),
      );

  void _beginOnboarding(BuildContext context) => _open(
        context,
        DisclaimerScreen(
          onDone: (profile) => setState(() => this.profile = profile),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: profile == null
              ? Column(
                  children: [
                    const Spacer(),
                    const StrandWiseLogo(size: 104),
                    const SizedBox(height: 24),
                    Text('Welcome to StrandWise', style: textTheme.headlineLarge),
                    const SizedBox(height: 12),
                    Text(
                      'Hair care that learns your hair, backed by real research.',
                      style: TextStyle(color: AppColors.muted),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _beginOnboarding(context),
                        child: const Text('Get started'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      SupabaseConfig.isConfigured
                          ? 'Your account is connected.'
                          : 'Your profile is stored on this device.',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                )
              : AppShell(
                  profile: profile!,
                  onEditProfile: () => _editProfile(context),
                ),
        ),
      ),
    );
  }
}
