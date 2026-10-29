import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/hair_profile.dart';
import '../../theme/app_theme.dart';

class SearchSourcesScreen extends StatelessWidget {
  const SearchSourcesScreen({super.key});

  static const _sources = [
    ('American Academy of Dermatology', 'https://www.aad.org/'),
    ('PubMed', 'https://pubmed.ncbi.nlm.nih.gov/'),
    ('NaturallyCurly', 'https://www.naturallycurly.com/'),
  ];

  Future<void> _openSource(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      children: [
        Text('Ask anything', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(
            hintText: 'Is rice water good for my hair?',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: const Padding(
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.pink, size: 16),
                    SizedBox(width: 6),
                    Text('Summary',
                        style: TextStyle(
                            color: AppColors.deepPink,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Rice water may add temporary strength, but evidence is '
                  'limited. Overuse can leave some hair feeling dry or stiff. '
                  'Try a patch test and stop if your hair becomes brittle.',
                  style: TextStyle(height: 1.45),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text('SOURCES',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
                letterSpacing: 1)),
        const SizedBox(height: 8),
        for (final source in _sources)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.pink,
                child: Icon(Icons.link, color: Colors.white, size: 18),
              ),
              title: Text(source.$1),
              subtitle: Text(Uri.parse(source.$2).host),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _openSource(source.$2),
            ),
          ),
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text(
            'Hair care information only. Not medical advice; see a doctor for scalp or hair loss concerns.',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ),
      ],
    );
  }
}

class IngredientCheckScreen extends StatelessWidget {
  const IngredientCheckScreen({super.key});

  static const _rows = [
    ('Glycerin', 'Humectant', 'Great', 0.9),
    ('Dimethicone', 'Silicone', 'Caution', 0.45),
    ('Panthenol', 'Moisture', 'Great', 0.8),
    ('Sodium Laureth Sulfate', 'Cleanser', 'Harsh', 0.25),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      children: [
        Text('Ingredient check',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        const Text('Hydrating Curl Cream',
            style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                SizedBox(
                  height: 76,
                  width: 76,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: .72,
                        strokeWidth: 9,
                        backgroundColor: AppColors.rose,
                        color: AppColors.pink,
                      ),
                      Text('72',
                          style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Good match',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text('Fits your profile, but contains one silicone.',
                          style:
                              TextStyle(fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final row in _rows)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(row.$1,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      Text(row.$3,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                  Text(row.$2,
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.muted)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: row.$4,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                    backgroundColor: AppColors.rose,
                    color: AppColors.pink,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class ProfileHubScreen extends StatelessWidget {
  const ProfileHubScreen({
    super.key,
    required this.profile,
    required this.onEditProfile,
  });

  final HairProfile profile;
  final VoidCallback onEditProfile;

  void _open(BuildContext context, Widget page) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => page),
      );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      children: [
        Text('Your space', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text('${profile.curlPattern} hair profile',
            style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 16),
        Card(
          color: AppColors.pink,
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, color: Colors.white),
                SizedBox(height: 10),
                Text('Private by default',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18)),
                SizedBox(height: 4),
                Text('Nothing leaves your phone unless you choose to.',
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ProfileLink(
          icon: Icons.photo_camera_back_outlined,
          title: 'Progress',
          subtitle: 'Keep a private visual journal',
          onTap: () => _open(context, const ProgressScreen()),
        ),
        _ProfileLink(
          icon: Icons.cloud_off_outlined,
          title: 'Offline and sync',
          subtitle: 'See what works without a connection',
          onTap: () => _open(context, const OfflineSyncScreen()),
        ),
        _ProfileLink(
          icon: Icons.lock_outline,
          title: 'Your privacy',
          subtitle: 'Understand how your data is handled',
          onTap: () => _open(context, const PrivacyScreen()),
        ),
        _ProfileLink(
          icon: Icons.tune,
          title: 'Hair profile',
          subtitle: 'Update your preferences',
          onTap: onEditProfile,
        ),
      ],
    );
  }
}

class _ProfileLink extends StatelessWidget {
  const _ProfileLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.rose,
            child: Icon(icon, color: AppColors.deepPink),
          ),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const heights = [.4, .52, .48, .66, .74, .82];
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Row(
            children: [
              Icon(Icons.lock_outline, size: 14, color: AppColors.muted),
              SizedBox(width: 5),
              Text('Photos are stored only on this device',
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final label in ['Week 1', 'Week 4', 'Week 8'])
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 126,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: AppColors.rose,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Center(
                          child: Icon(Icons.person_outline,
                              color: AppColors.deepPink, size: 30),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(label,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.muted)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Moisture score',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(
                    height: 100,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var index = 0; index < heights.length; index++)
                          Expanded(
                            child: Container(
                              height: 80 * heights[index],
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: index == heights.length - 1
                                    ? AppColors.pink
                                    : AppColors.rose,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Text('Up 42% since you started',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Add progress photo'),
          ),
        ],
      ),
    );
  }
}

class OfflineSyncScreen extends StatelessWidget {
  const OfflineSyncScreen({super.key});

  static const _items = [
    ('Routines', 'Saved on device', true),
    ('Reminders', 'Scheduled locally', true),
    ('Wash day log', 'Changes waiting to sync', false),
    ('Search and videos', 'Needs a connection', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline and sync')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: AppColors.rose,
            child: const ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.cloud_off_outlined, color: AppColors.pink),
              ),
              title: Text('You are offline'),
              subtitle: Text('Everything you need for your routine still works.'),
            ),
          ),
          const SizedBox(height: 12),
          for (final item in _items)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  item.$3 ? Icons.check_circle : Icons.circle_outlined,
                  color: item.$3 ? AppColors.pink : AppColors.muted,
                ),
                title: Text(item.$1),
                subtitle: Text(item.$2),
              ),
            ),
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Sync never sends your photos or hair profile. Not medical advice.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const _rows = [
    ('Hair photos', 'Stay on this device', Icons.photo_outlined),
    ('Profile and hair type', 'Never shared or sold', Icons.person_outline),
    ('Routines and reminders', 'Work fully offline', Icons.cloud_off_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your privacy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: AppColors.pink,
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Color(0x33FFFFFF),
                    child: Icon(Icons.lock_outline, color: Colors.white),
                  ),
                  SizedBox(height: 12),
                  Text('Private by default',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18)),
                  SizedBox(height: 4),
                  Text('Nothing leaves your phone unless you choose to.',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final row in _rows)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.rose,
                  child: Icon(row.$3, color: AppColors.deepPink),
                ),
                title: Text(row.$1),
                subtitle: Text(row.$2),
                trailing: const Icon(Icons.toggle_on,
                    color: AppColors.pink, size: 34),
              ),
            ),
          Card(
            color: AppColors.rose,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Not medical advice. StrandWise offers general hair care guidance and cited research. It does not diagnose or treat conditions.',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
