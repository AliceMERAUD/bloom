import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/wellbeing_entry.dart';
import '../../models/wellbeing_enums.dart';
import '../../services/wellbeing_service.dart';
import '../../widgets/common/bloom_widgets.dart';
import 'wellbeing_entry_screen.dart';

/// Simple month grid highlighting days with wellbeing entries / period.
class WellbeingMonthCalendar extends StatefulWidget {
  final ValueChanged<DateTime>? onDaySelected;

  const WellbeingMonthCalendar({super.key, this.onDaySelected});

  @override
  State<WellbeingMonthCalendar> createState() => _WellbeingMonthCalendarState();
}

class _WellbeingMonthCalendarState extends State<WellbeingMonthCalendar> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _shift(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = {
      for (final e in WellbeingService.getAllEntries())
        DateTime(e.date.year, e.date.month, e.date.day): e,
    };
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // Monday=0 .. Sunday=6
    final startWeekday = (first.weekday + 6) % 7;

    final months = const [
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

    return BloomCard(
      accent: BloomTheme.wellbeing,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Mois précédent',
                onPressed: () => _shift(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${months[_month.month - 1]} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: 'Mois suivant',
                onPressed: () => _shift(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 4),
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
              final day = index - startWeekday + 1;
              final date = DateTime(_month.year, _month.month, day);
              final key = DateTime(date.year, date.month, date.day);
              final entry = entries[key];
              final hasPeriod = entry != null &&
                  (entry.bleeding != Bleeding.none ||
                      entry.periodMarker != PeriodMarker.none);
              final today = DateTime.now();
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;

              Color? bg;
              if (entry != null) {
                bg = BloomTheme.wellbeing.withValues(alpha: 0.22);
              }
              if (hasPeriod) {
                bg = const Color(0xFFE57373).withValues(alpha: 0.35);
              }

              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  widget.onDaySelected?.call(date);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                    border: isToday
                        ? Border.all(color: BloomTheme.wellbeing, width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontWeight: entry != null ? FontWeight.bold : null,
                            fontSize: 12,
                          ),
                        ),
                        if (entry?.mood != null || entry?.energy != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (entry?.mood != null)
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.only(right: 2),
                                  decoration: BoxDecoration(
                                    color: _moodColor(entry!.mood!),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (entry?.energy != null)
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: _energyColor(entry!.energy!),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _legend(BloomTheme.wellbeing.withValues(alpha: 0.22), 'Suivi'),
              _legend(
                const Color(0xFFE57373).withValues(alpha: 0.35),
                'Règles',
              ),
              _legend(const Color(0xFF81C784), 'Humeur'),
              _legend(const Color(0xFFFFB74D), 'Énergie'),
            ],
          ),
        ],
      ),
    );
  }

  Color _moodColor(Mood mood) {
    switch (mood) {
      case Mood.veryGood:
      case Mood.good:
        return const Color(0xFF81C784);
      case Mood.neutral:
        return const Color(0xFFFFD54F);
      case Mood.bad:
      case Mood.veryBad:
        return const Color(0xFFE57373);
    }
  }

  Color _energyColor(Energy energy) {
    switch (energy) {
      case Energy.veryGood:
      case Energy.good:
        return const Color(0xFFFFB74D);
      case Energy.medium:
        return const Color(0xFFFFCC80);
      case Energy.low:
      case Energy.veryLow:
        return const Color(0xFF90A4AE);
    }
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

Future<void> openWellbeingDay(BuildContext context, DateTime date) async {
  WellbeingEntry? existing;
  try {
    existing = WellbeingService.getEntryForDate(date);
  } catch (_) {}
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => WellbeingEntryScreen(
        initialDate: date,
        existing: existing,
      ),
    ),
  );
}
