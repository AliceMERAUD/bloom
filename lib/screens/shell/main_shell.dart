import 'package:flutter/material.dart';

import '../../services/bloom_refresh.dart';
import '../../services/puzzle_progress_service.dart';
import '../home/home_screen.dart';
import '../puzzle/puzzle_play_screen.dart';
import '../puzzle/puzzle_screen.dart';
import '../settings/settings_screen.dart';
import '../sport/sport_screen.dart';
import '../tasks/task_form_screen.dart';
import '../tasks/tasks_screen.dart';
import '../wellbeing/wellbeing_entry_screen.dart';
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
  final GlobalKey<SportScreenState> _sportKey = GlobalKey<SportScreenState>();

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

  Future<void> _startSessionShortcut() async {
    goToTab(1);
    // Let the Sport tab become visible before triggering the session flow.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await _sportKey.currentState?.startSessionFromShortcut();
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
            onAddTask: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TaskFormScreen()),
              );
              BloomRefresh.notify();
            },
            onAddWellbeing: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WellbeingEntryScreen(
                    initialDate: DateTime.now(),
                  ),
                ),
              );
              BloomRefresh.notify();
            },
            onContinuePuzzle: () {
              final id = PuzzleProgressService.load().nextPlayableId;
              if (id == null) {
                goToTab(4);
                return;
              }
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (_) => PuzzlePlayScreen(puzzleId: id),
                    ),
                  )
                  .then((_) => BloomRefresh.notify());
            },
            onStartSession: _startSessionShortcut,
          ),
          SportScreen(key: _sportKey),
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
