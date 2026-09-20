import 'package:flutter/material.dart';

import '../models/planning_event.dart';
import '../models/task.dart';
import '../models/wellbeing_entry.dart';
import '../models/wellbeing_enums.dart';
import '../models/workout_session.dart';
import 'sport_activity_service.dart';
import 'storage_service.dart';
import 'task_service.dart';
import 'wellbeing_service.dart';

/// Aggregates existing Bloom data into a planning timeline (no parallel store).
class PlanningService {
  static List<PlanningEvent> eventsForDay(DateTime day) {
    final key = PlanningEvent.dayOnly(day);
    return eventsInRange(key, key);
  }

  /// Inclusive range of calendar days.
  static List<PlanningEvent> eventsInRange(DateTime start, DateTime end) {
    final from = PlanningEvent.dayOnly(start);
    final to = PlanningEvent.dayOnly(end);
    final events = <PlanningEvent>[
      ..._taskEvents(from, to),
      ..._sessionEvents(from, to),
      ..._periodEvents(from, to),
    ];
    events.sort((a, b) {
      final byDay = a.day.compareTo(b.day);
      if (byDay != 0) return byDay;
      final byTime = a.sortMinutes.compareTo(b.sortMinutes);
      if (byTime != 0) return byTime;
      return a.title.compareTo(b.title);
    });
    return events;
  }

  static Map<DateTime, PlanningDayMarkers> markersInRange(
    DateTime start,
    DateTime end,
  ) {
    final map = <DateTime, PlanningDayMarkers>{};
    for (final event in eventsInRange(start, end)) {
      final key = PlanningEvent.dayOnly(event.day);
      final next = PlanningDayMarkers.fromEvents([event]);
      map[key] = (map[key] ?? const PlanningDayMarkers()).merge(next);
    }
    return map;
  }

  static int countForDay(DateTime day) => eventsForDay(day).length;

  /// Next upcoming items after [from] (defaults to now), limited.
  static List<PlanningEvent> upcoming({
    DateTime? from,
    int limit = 5,
  }) {
    final now = from ?? DateTime.now();
    final start = PlanningEvent.dayOnly(now);
    final end = start.add(const Duration(days: 30));
    final all = eventsInRange(start, end);
    final filtered = all.where((e) {
      if (e.completed) return false;
      if (e.day.isAfter(start)) return true;
      if (!PlanningEvent.sameDay(e.day, start)) return false;
      if (e.time == null) return true;
      final minutes = e.time!.hour * 60 + e.time!.minute;
      final nowMinutes = now.hour * 60 + now.minute;
      return minutes >= nowMinutes;
    }).toList();
    return filtered.take(limit).toList();
  }

  static List<PlanningEvent> _taskEvents(DateTime from, DateTime to) {
    final out = <PlanningEvent>[];
    final seen = <String>{};

    for (final task in TaskService.getTasks()) {
      if (task.dueDate == null) continue;
      final day = PlanningEvent.dayOnly(task.dueDate!);
      if (day.isBefore(from) || day.isAfter(to)) continue;
      if (!seen.add(task.id)) continue;

      final sport = task.sportId == null
          ? null
          : SportActivityService.getById(task.sportId!);
      final isSport = task.category == TaskCategory.sport || sport != null;
      final title = sport?.name ?? task.title;
      final kind = isSport
          ? PlanningEventKind.sportActivity
          : PlanningEventKind.task;

      out.add(
        PlanningEvent(
          id: 'task_${task.id}',
          kind: kind,
          day: day,
          time: task.dueTime,
          title: title,
          subtitle: isSport && sport != null && sport.name != task.title
              ? task.title
              : (task.completed ? 'Terminée' : null),
          icon: sport?.icon ?? task.category.icon,
          accent: accentForKind(kind),
          taskId: task.id,
          sportId: task.sportId,
          completed: task.completed,
        ),
      );
    }
    return out;
  }

  static List<PlanningEvent> _sessionEvents(DateTime from, DateTime to) {
    final out = <PlanningEvent>[];
    List<WorkoutSession> sessions = const [];
    try {
      sessions = StorageService.getAllSessions();
    } catch (_) {
      return out;
    }

    for (final session in sessions) {
      final day = PlanningEvent.dayOnly(session.startedAt);
      if (day.isBefore(from) || day.isAfter(to)) continue;
      final time = TimeOfDay(
        hour: session.startedAt.hour,
        minute: session.startedAt.minute,
      );
      out.add(
        PlanningEvent(
          id: 'session_${session.id}',
          kind: PlanningEventKind.workoutSession,
          day: day,
          time: time,
          title: session.isOpen ? 'Musculation (en cours)' : 'Musculation',
          subtitle: session.isOpen
              ? 'Séance ouverte'
              : (session.duration == null
                  ? null
                  : _formatDuration(session.duration!)),
          icon: Icons.fitness_center,
          accent: accentForKind(PlanningEventKind.workoutSession),
          sessionId: session.id,
          completed: !session.isOpen,
        ),
      );
    }
    return out;
  }

  static List<PlanningEvent> _periodEvents(DateTime from, DateTime to) {
    final days = <DateTime>{};

    // Recorded entries with bleeding or period markers only (no prediction).
    try {
      for (final entry in WellbeingService.getAllEntries()) {
        final day = PlanningEvent.dayOnly(entry.date);
        if (day.isBefore(from) || day.isAfter(to)) continue;
        if (entry.bleeding != Bleeding.none ||
            entry.periodMarker != PeriodMarker.none) {
          days.add(day);
        }
      }
    } catch (_) {}

    // Fill closed/open recorded period spans between start and end markers.
    try {
      for (final period in WellbeingService.getPeriods()) {
        final start = PlanningEvent.dayOnly(period.start);
        final end = period.end == null
            ? PlanningEvent.dayOnly(DateTime.now())
            : PlanningEvent.dayOnly(period.end!);
        var cursor = start.isBefore(from) ? from : start;
        final last = end.isAfter(to) ? to : end;
        while (!cursor.isAfter(last)) {
          days.add(cursor);
          cursor = cursor.add(const Duration(days: 1));
        }
      }
    } catch (_) {}

    return days.map((day) {
      WellbeingEntry? entry;
      try {
        entry = WellbeingService.getEntryForDate(day);
      } catch (_) {}
      final bleeding = entry?.bleeding;
      final subtitle = bleeding == null || bleeding == Bleeding.none
          ? null
          : 'Saignement : ${bleeding.label}';
      return PlanningEvent(
        id: 'period_${WellbeingEntry.dateKey(day)}',
        kind: PlanningEventKind.period,
        day: day,
        title: 'Règles',
        subtitle: subtitle,
        icon: Icons.water_drop,
        accent: accentForKind(PlanningEventKind.period),
        wellbeingDate: day,
      );
    }).toList();
  }

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}min';
    }
    return '$minutes min';
  }
}
