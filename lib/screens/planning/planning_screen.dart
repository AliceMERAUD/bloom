import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/planning_event.dart';
import '../../models/task.dart';
import '../../services/bloom_refresh.dart';
import '../../services/planning_service.dart';
import '../../services/task_service.dart';
import '../../widgets/common/bloom_widgets.dart';
import '../sport/session_detail_screen.dart';
import '../sport/sport_screen.dart';
import '../tasks/task_form_screen.dart';
import '../wellbeing/wellbeing_month_calendar.dart' show openWellbeingDay;

enum PlanningViewMode { day, week, month }

/// Global calendar aggregating tasks, sport sessions and recorded period days.
class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  PlanningViewMode _mode = PlanningViewMode.day;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = PlanningEvent.dayOnly(DateTime.now());
    BloomRefresh.version.addListener(_onRefresh);
  }

  @override
  void dispose() {
    BloomRefresh.version.removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh() {
    if (mounted) setState(() {});
  }

  DateTime get _today => PlanningEvent.dayOnly(DateTime.now());

  void _goToday() => setState(() => _selected = _today);

  void _shift(int delta) {
    setState(() {
      switch (_mode) {
        case PlanningViewMode.day:
          _selected = _selected.add(Duration(days: delta));
        case PlanningViewMode.week:
          _selected = _selected.add(Duration(days: 7 * delta));
        case PlanningViewMode.month:
          _selected = DateTime(_selected.year, _selected.month + delta, 1);
      }
    });
  }

  DateTime get _weekStart {
    final weekday = (_selected.weekday + 6) % 7; // Monday=0
    return _selected.subtract(Duration(days: weekday));
  }

  String get _headerLabel {
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    const weekdays = [
      'lundi',
      'mardi',
      'mercredi',
      'jeudi',
      'vendredi',
      'samedi',
      'dimanche',
    ];
    switch (_mode) {
      case PlanningViewMode.day:
        final wd = weekdays[(_selected.weekday + 6) % 7];
        return '${_cap(wd)} ${_selected.day} ${months[_selected.month - 1]}';
      case PlanningViewMode.week:
        final start = _weekStart;
        final end = start.add(const Duration(days: 6));
        if (start.month == end.month) {
          return '${start.day}–${end.day} ${months[start.month - 1]} ${start.year}';
        }
        return '${start.day} ${months[start.month - 1]} – '
            '${end.day} ${months[end.month - 1]}';
      case PlanningViewMode.month:
        return '${_cap(months[_selected.month - 1])} ${_selected.year}';
    }
  }

  String _cap(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  Future<void> _openAdd() async {
    final choice = await showModalBottomSheet<_AddChoice>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.check_circle_outline, color: BloomTheme.tasks),
                title: const Text('Tâche'),
                onTap: () => Navigator.pop(ctx, _AddChoice.task),
              ),
              ListTile(
                leading: Icon(Icons.fitness_center, color: BloomTheme.sport),
                title: const Text('Sport'),
                subtitle: const Text('Activité sportive planifiée'),
                onTap: () => Navigator.pop(ctx, _AddChoice.sport),
              ),
              ListTile(
                leading: Icon(Icons.favorite_outline, color: BloomTheme.wellbeing),
                title: const Text('Bien-être'),
                subtitle: const Text('Entrée Wellbeing du jour sélectionné'),
                onTap: () => Navigator.pop(ctx, _AddChoice.wellbeing),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || choice == null) return;

    switch (choice) {
      case _AddChoice.task:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TaskFormScreen(initialDueDate: _selected),
          ),
        );
      case _AddChoice.sport:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TaskFormScreen(
              initialDueDate: _selected,
              initialCategory: TaskCategory.sport,
            ),
          ),
        );
      case _AddChoice.wellbeing:
        await openWellbeingDay(context, _selected);
    }
    BloomRefresh.notify();
    if (mounted) setState(() {});
  }

  Future<void> _openEvent(PlanningEvent event) async {
    switch (event.kind) {
      case PlanningEventKind.task:
      case PlanningEventKind.sportActivity:
        if (event.taskId == null) return;
        final task = TaskService.getById(event.taskId!);
        if (task == null) return;
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
        );
      case PlanningEventKind.workoutSession:
        if (event.sessionId == null) {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SportScreen()),
          );
          return;
        }
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SessionDetailScreen(sessionId: event.sessionId!),
          ),
        );
      case PlanningEventKind.period:
        final date = event.wellbeingDate ?? event.day;
        await openWellbeingDay(context, date);
    }
    BloomRefresh.notify();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planning'),
        actions: [
          TextButton(
            onPressed: _goToday,
            child: const Text('Aujourd’hui'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        tooltip: 'Ajouter',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: SegmentedButton<PlanningViewMode>(
              segments: const [
                ButtonSegment(
                  value: PlanningViewMode.day,
                  label: Text('Jour'),
                  icon: Icon(Icons.view_day_outlined, size: 18),
                ),
                ButtonSegment(
                  value: PlanningViewMode.week,
                  label: Text('Semaine'),
                  icon: Icon(Icons.view_week_outlined, size: 18),
                ),
                ButtonSegment(
                  value: PlanningViewMode.month,
                  label: Text('Mois'),
                  icon: Icon(Icons.calendar_month_outlined, size: 18),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (value) {
                setState(() => _mode = value.first);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Précédent',
                  onPressed: () => _shift(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    _headerLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Suivant',
                  onPressed: () => _shift(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (_mode) {
              PlanningViewMode.day => _DayView(
                  day: _selected,
                  onOpen: _openEvent,
                ),
              PlanningViewMode.week => _WeekView(
                  weekStart: _weekStart,
                  selected: _selected,
                  onSelectDay: (d) => setState(() {
                    _selected = d;
                    _mode = PlanningViewMode.day;
                  }),
                  onOpen: _openEvent,
                ),
              PlanningViewMode.month => _MonthView(
                  month: DateTime(_selected.year, _selected.month),
                  selected: _selected,
                  onSelectDay: (d) => setState(() {
                    _selected = d;
                    _mode = PlanningViewMode.day;
                  }),
                ),
            },
          ),
        ],
      ),
    );
  }
}

enum _AddChoice { task, sport, wellbeing }

class _DayView extends StatelessWidget {
  final DateTime day;
  final ValueChanged<PlanningEvent> onOpen;

  const _DayView({required this.day, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final events = PlanningService.eventsForDay(day);
    if (events.isEmpty) {
      return const BloomEmptyState(
        icon: Icons.event_available_outlined,
        message: 'Rien de prévu — ajoute une tâche ou une activité avec +.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _EventTile(event: events[index], onOpen: onOpen);
      },
    );
  }
}

class _WeekView extends StatelessWidget {
  final DateTime weekStart;
  final DateTime selected;
  final ValueChanged<DateTime> onSelectDay;
  final ValueChanged<PlanningEvent> onOpen;

  const _WeekView({
    required this.weekStart,
    required this.selected,
    required this.onSelectDay,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final end = days.last;
    final markers = PlanningService.markersInRange(weekStart, end);
    final events = PlanningService.eventsInRange(weekStart, end);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
      children: [
        Row(
          children: days.map((day) {
            final m = markers[PlanningEvent.dayOnly(day)] ??
                const PlanningDayMarkers();
            final isSelected = PlanningEvent.sameDay(day, selected);
            final isToday = PlanningEvent.sameDay(day, DateTime.now());
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSelectDay(day),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? BloomTheme.planning.withValues(alpha: 0.18)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    border: isToday
                        ? Border.all(color: BloomTheme.planning, width: 1.5)
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        const ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                            [(day.weekday + 6) % 7],
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _MarkerDots(markers: m, size: 5),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        ...days.map((day) {
          final dayEvents = events
              .where((e) => PlanningEvent.sameDay(e.day, day))
              .toList();
          if (dayEvents.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _shortDayLabel(day),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                ...dayEvents.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _EventTile(event: e, onOpen: onOpen, compact: true),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _shortDayLabel(DateTime day) {
    const names = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    return '${names[(day.weekday + 6) % 7]} ${day.day}';
  }
}

class _MonthView extends StatelessWidget {
  final DateTime month;
  final DateTime selected;
  final ValueChanged<DateTime> onSelectDay;

  const _MonthView({
    required this.month,
    required this.selected,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startWeekday = (first.weekday + 6) % 7;
    final markers = PlanningService.markersInRange(
      first,
      DateTime(month.year, month.month, daysInMonth),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
      children: [
        BloomCard(
          accent: BloomTheme.planning,
          child: Column(
            children: [
              Row(
                children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 6),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: startWeekday + daysInMonth,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemBuilder: (context, index) {
                  if (index < startWeekday) {
                    return const SizedBox.shrink();
                  }
                  final dayNum = index - startWeekday + 1;
                  final date = DateTime(month.year, month.month, dayNum);
                  final key = PlanningEvent.dayOnly(date);
                  final m = markers[key] ?? const PlanningDayMarkers();
                  final isSelected = PlanningEvent.sameDay(date, selected);
                  final isToday = PlanningEvent.sameDay(date, DateTime.now());

                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onSelectDay(date),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? BloomTheme.planning.withValues(alpha: 0.2)
                            : null,
                        borderRadius: BorderRadius.circular(10),
                        border: isToday
                            ? Border.all(
                                color: BloomTheme.planning,
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNum',
                            style: TextStyle(
                              fontWeight: m.isNotEmpty || isSelected
                                  ? FontWeight.bold
                                  : null,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          _MarkerDots(markers: m, size: 4),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              const Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _LegendDot(color: BloomTheme.sport, label: 'Sport'),
                  _LegendDot(color: BloomTheme.wellbeing, label: 'Règles'),
                  _LegendDot(color: BloomTheme.tasks, label: 'Tâche'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Appuie sur un jour pour voir le détail',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _MarkerDots extends StatelessWidget {
  final PlanningDayMarkers markers;
  final double size;

  const _MarkerDots({required this.markers, this.size = 5});

  @override
  Widget build(BuildContext context) {
    if (markers.isEmpty) {
      return SizedBox(height: size);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (markers.hasSport)
          _dot(BloomTheme.sport),
        if (markers.hasPeriod) ...[
          if (markers.hasSport) SizedBox(width: size > 4 ? 2 : 1),
          _dot(BloomTheme.wellbeing),
        ],
        if (markers.hasTask) ...[
          if (markers.hasSport || markers.hasPeriod)
            SizedBox(width: size > 4 ? 2 : 1),
          _dot(BloomTheme.tasks),
        ],
      ],
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  final PlanningEvent event;
  final ValueChanged<PlanningEvent> onOpen;
  final bool compact;

  const _EventTile({
    required this.event,
    required this.onOpen,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeLabel = event.time == null
        ? null
        : '${event.time!.hour.toString().padLeft(2, '0')}:'
            '${event.time!.minute.toString().padLeft(2, '0')}';

    return BloomCard(
      accent: event.accent,
      elevated: !compact,
      onTap: () => onOpen(event),
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: compact ? 10 : 14,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: compact ? 16 : 20,
            backgroundColor: event.accent.withValues(alpha: 0.18),
            child: Icon(event.icon, color: event.accent, size: compact ? 16 : 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration:
                        event.completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (event.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    event.subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (timeLabel != null)
            BloomBadge(label: timeLabel, color: event.accent)
          else if (event.kind == PlanningEventKind.period)
            BloomBadge(label: 'Journée', color: event.accent),
        ],
      ),
    );
  }
}
