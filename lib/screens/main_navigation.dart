import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import 'home/home_screen.dart';
import 'friends/friends_screen.dart';
import 'leaderboard/leaderboard_screen.dart';
import 'settings/settings_screen.dart';

/// MainNavigationScreen with bottom navigation bar
/// Requirements: 1.1, 1.2, 1.3, 1.4
class MainNavigationScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  // List of screens corresponding to navigation items
  final List<Widget> _screens = const [
    HomeScreen(),
    FriendsScreen(),
    LeaderboardScreen(),
    SettingsScreen(),
  ];

  /// Handle navigation item tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomNavTheme = Theme.of(context).bottomNavigationBarTheme;

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: bottomNavTheme.type ?? BottomNavigationBarType.fixed,
        backgroundColor: bottomNavTheme.backgroundColor,
        selectedItemColor: bottomNavTheme.selectedItemColor,
        unselectedItemColor: bottomNavTheme.unselectedItemColor,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        elevation: bottomNavTheme.elevation ?? 8,
        selectedLabelStyle:
            bottomNavTheme.selectedLabelStyle?.copyWith(letterSpacing: 0.5) ??
            const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home, size: 28),
            label: l10n.dashboard.toUpperCase(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.sports_martial_arts, size: 28),
            label: l10n.vsMode.toUpperCase(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.leaderboard, size: 28),
            label: l10n.leaderboard.toUpperCase(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person, size: 28),
            label: l10n.settings.toUpperCase(),
          ),
        ],
      ),
    );
  }
}
