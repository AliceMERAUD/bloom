import 'package:flutter/material.dart';

import '../../services/bloom_refresh.dart';
import '../home/home_screen.dart';
import '../puzzle/puzzle_screen.dart';
import '../settings/settings_screen.dart';
import '../sport/sport_screen.dart';
import '../tasks/tasks_screen.dart';
import '../wellbeing/wellbeing_screen.dart';

/// Root shell: Home / Sport / Wellbeing / Tasks / Puzzle.
class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  void goToTab(int index) {
    final next = index.clamp(0, 4);
    if (next == 0) {
      BloomRefresh.notify();
    }
    setState(() => _index = next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(
            onOpenSport: () => goToTab(1),
            onOpenWellbeing: () => goToTab(2),
            onOpenTasks: () => goToTab(3),
            onOpenPuzzle: () => goToTab(4),
            onOpenSettings: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SportScreen(),
          const WellbeingScreen(),
          const TasksScreen(),
          const PuzzleScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: goToTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Sport',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Bien-être',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.extension_outlined),
            selectedIcon: Icon(Icons.extension),
            label: 'Puzzle',
          ),
        ],
      ),
    );
  }
}
