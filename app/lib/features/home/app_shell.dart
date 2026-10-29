import 'package:flutter/material.dart';

import '../../features/content/content_hub_screen.dart';
import '../../features/routine/routine_screen.dart';
import '../../models/hair_profile.dart';
import '../profile/profile_screens.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.profile,
    required this.onEditProfile,
  });

  final HairProfile profile;
  final VoidCallback onEditProfile;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      RoutineScreen(profile: widget.profile),
      ContentHubScreen(profile: widget.profile),
      const SearchSourcesScreen(),
      const IngredientCheckScreen(),
      ProfileHubScreen(
        profile: widget.profile,
        onEditProfile: widget.onEditProfile,
      ),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Routine'),
          NavigationDestination(
              icon: Icon(Icons.play_circle_outline), label: 'Learn'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
              icon: Icon(Icons.science_outlined), label: 'Ingredients'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
