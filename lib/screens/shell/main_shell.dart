import 'package:flutter/material.dart';

import '../../app/theme.dart';
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

/// Root shell: Accueil / Tasks / Sport / Bien-être / Plus.
class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  late int _index;
  final GlobalKey<SportScreenState> _sportKey = GlobalKey<SportScreenState>();

  static const int _tabCount = 4; // Accueil, Tasks, Sport, Bien-être
  static const int _moreIndex = 4;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, _tabCount - 1);
  }

  void goToTab(int index) {
    final next = index.clamp(0, _tabCount - 1);
    if (next == 0) {
      BloomRefresh.notify();
    }
    setState(() => _index = next);
  }

  Future<void> _startSessionShortcut() async {
    goToTab(2); // Sport
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await _sportKey.currentState?.startSessionFromShortcut();
  }

  Future<void> _openPuzzle() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PuzzleScreen()),
    );
    BloomRefresh.notify();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    BloomRefresh.notify();
  }

  Future<void> _showMoreMenu() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.extension, color: BloomTheme.puzzle),
                title: const Text('Puzzle'),
                onTap: () => Navigator.pop(ctx, 'puzzle'),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Paramètres'),
                onTap: () => Navigator.pop(ctx, 'settings'),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'puzzle':
        await _openPuzzle();
      case 'settings':
        await _openSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(
            onOpenSport: () => goToTab(2),
            onOpenWellbeing: () => goToTab(3),
            onOpenTasks: () => goToTab(1),
            onOpenPuzzle: _openPuzzle,
            onOpenGoogleCalendar: _openSettings,
            onOpenSettings: _openSettings,
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
                _openPuzzle();
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
          const TasksScreen(),
          SportScreen(key: _sportKey),
          const WellbeingScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          if (i == _moreIndex) {
            _showMoreMenu();
            return;
          }
          goToTab(i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tasks',
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
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'Plus',
          ),
        ],
      ),
    );
  }
}
