import 'package:flutter/material.dart';

import '../../features/calendar/wash_calendar_screen.dart';
import '../../features/content/content_hub_screen.dart';
import '../../features/routine/routine_screen.dart';
import '../../models/hair_profile.dart';
import '../hairstyles/hairstyle_screen.dart';
import '../profile/profile_screens.dart';
import '../../widgets/mockup_bottom_navigation.dart';
import '../../widgets/strand_motion.dart';

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
      WashCalendarScreen(profile: widget.profile),
      HairstyleScreen(profile: widget.profile),
      ProfileHubScreen(
        profile: widget.profile,
        onEditProfile: widget.onEditProfile,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            for (var i = 0; i < pages.length; i++)
              TabEntrance(active: i == _selectedIndex, child: pages[i]),
          ],
        ),
      ),
      bottomNavigationBar: MockupBottomNavigation(
        currentIndex: _selectedIndex,
        onSelected: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
