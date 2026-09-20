import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Kind of item shown in the global Planning view.
enum PlanningEventKind {
  period,
  workoutSession,
  sportActivity,
  task,
}

/// Read-only calendar item aggregated from existing Bloom data.
class PlanningEvent {
  final String id;
  final PlanningEventKind kind;
  final DateTime day;
  final TimeOfDay? time;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accent;

  /// Source ids for navigation (null when not applicable).
  final String? taskId;
  final String? sessionId;
  final String? sportId;
  final DateTime? wellbeingDate;

  final bool completed;

  const PlanningEvent({
    required this.id,
    required this.kind,
    required this.day,
    required this.title,
    required this.icon,
    required this.accent,
    this.time,
    this.subtitle,
    this.taskId,
    this.sessionId,
    this.sportId,
    this.wellbeingDate,
    this.completed = false,
  });

  int get sortMinutes {
    if (time == null) return 24 * 60 + 1;
    return time!.hour * 60 + time!.minute;
  }

  static DateTime dayOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Compact day markers for month/week overview.
class PlanningDayMarkers {
  final bool hasSport;
  final bool hasPeriod;
  final bool hasTask;

  const PlanningDayMarkers({
    this.hasSport = false,
    this.hasPeriod = false,
    this.hasTask = false,
  });

  bool get isEmpty => !hasSport && !hasPeriod && !hasTask;
  bool get isNotEmpty => !isEmpty;

  int get count =>
      (hasSport ? 1 : 0) + (hasPeriod ? 1 : 0) + (hasTask ? 1 : 0);

  PlanningDayMarkers merge(PlanningDayMarkers other) {
    return PlanningDayMarkers(
      hasSport: hasSport || other.hasSport,
      hasPeriod: hasPeriod || other.hasPeriod,
      hasTask: hasTask || other.hasTask,
    );
  }

  static PlanningDayMarkers fromEvents(Iterable<PlanningEvent> events) {
    var sport = false;
    var period = false;
    var task = false;
    for (final e in events) {
      switch (e.kind) {
        case PlanningEventKind.period:
          period = true;
        case PlanningEventKind.workoutSession:
        case PlanningEventKind.sportActivity:
          sport = true;
        case PlanningEventKind.task:
          task = true;
      }
    }
    return PlanningDayMarkers(
      hasSport: sport,
      hasPeriod: period,
      hasTask: task,
    );
  }
}

Color accentForKind(PlanningEventKind kind) {
  switch (kind) {
    case PlanningEventKind.period:
      return BloomTheme.wellbeing;
    case PlanningEventKind.workoutSession:
    case PlanningEventKind.sportActivity:
      return BloomTheme.sport;
    case PlanningEventKind.task:
      return BloomTheme.tasks;
  }
}
