import 'package:flutter/material.dart';

import '../../models/hair_profile.dart';
import '../../theme/app_theme.dart';
import 'onboarding_screen.dart';

class DisclaimerScreen extends StatefulWidget {
  const DisclaimerScreen({super.key, required this.onDone});

  final ValueChanged<HairProfile> onDone;

  @override
  State<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends State<DisclaimerScreen> {
  bool _understood = false;

  void _continue() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => OnboardingScreen(
          onDone: widget.onDone,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: AppColors.rose,
                          shape: BoxShape.circle,
                        ),
                        child:
                            const Icon(Icons.info_outline, color: AppColors.pink),
                      ),
                      const SizedBox(height: 24),
                      Text('Before we begin',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 16),
                      Card(
                        child: const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'StrandWise provides general hair care information and '
                            'personalized suggestions for educational purposes only.\n\n'
                            'It is not medical advice. It does not diagnose, treat, or '
                            'prevent any condition. Talk to a doctor or dermatologist '
                            'about hair loss, scalp pain, rashes, or other health concerns.\n\n'
                            'Suggestions are based on your hair profile and cited '
                            'sources. Check sources before relying on them.',
                            style: TextStyle(height: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _understood,
                        activeColor: AppColors.pink,
                        onChanged: (value) =>
                            setState(() => _understood = value ?? false),
                        title: const Text(
                          'I understand StrandWise is not a substitute for professional medical advice.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _understood ? _continue : null,
                  child: const Text('I understand, continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
