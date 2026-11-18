import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'data/profile_store.dart';
import 'features/home/app_shell.dart';
import 'features/onboarding/disclaimer_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'models/hair_profile.dart';
import 'theme/app_theme.dart';
import 'widgets/strand_motion.dart';
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
    ProfileStore.load()
        .then((p) {
          if (mounted) setState(() => profile = p);
        })
        .catchError((_) {});
  }

  void _open(BuildContext context, Widget screen) =>
      Navigator.of(context)
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
      onDone: (profile) {
        setState(() => this.profile = profile);
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: profile == null
          ? StrandWaveBackground(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Spacer(),
                      const FadeSlideIn(
                        duration: Duration(milliseconds: 700),
                        child: Floating(child: StrandWiseLogo(size: 104)),
                      ),
                      const SizedBox(height: 24),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 150),
                        child: Text(
                          'StrandWise',
                          style: textTheme.headlineLarge,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const FadeSlideIn(
                        delay: Duration(milliseconds: 300),
                        child: Text(
                          'Hair care that learns your hair, backed by real research.',
                          style: TextStyle(color: AppColors.muted),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Spacer(),
                      const _PageIndicator(),
                      const SizedBox(height: 24),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 450),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => _beginOnboarding(context),
                            child: const Text('Get started'),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('I already have an account'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : AppShell(
              profile: profile!,
              onEditProfile: () => _editProfile(context),
            ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _IndicatorDot(active: true),
      SizedBox(width: 6),
      _IndicatorDot(),
      SizedBox(width: 6),
      _IndicatorDot(),
    ],
  );
}

class _IndicatorDot extends StatelessWidget {
  const _IndicatorDot({this.active = false});

  final bool active;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOut,
    height: 7,
    width: active ? 24 : 7,
    decoration: BoxDecoration(
      color: active ? AppColors.pink : AppColors.rose,
      borderRadius: BorderRadius.circular(4),
    ),
  );
}
