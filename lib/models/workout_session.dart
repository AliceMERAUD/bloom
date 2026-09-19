class WorkoutSession {
  final String id;
  final DateTime date;
  final List<String> setIds;

  const WorkoutSession({
    required this.id,
    required this.date,
    required this.setIds,
  });
}