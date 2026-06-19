// lib/features/forecast/widgets/hour_scrubber.dart
import 'package:flutter/material.dart';

import '../../../data/mock/mock_flight_data.dart';
import '../../../domain/i18n/app_strings.dart';
import '../../../domain/i18n/language.dart';
import '../forecast_day_grouping.dart';
import 'focused_hour_card.dart';

class HourScrubber extends StatelessWidget {
  const HourScrubber({
    super.key,
    required this.days,
    required this.selectedDate,
    required this.selectedHour,
    required this.today,
    required this.language,
    required this.onHourSelected,
    required this.onDaySelected,
    required this.onGoToBest,
  });

  final List<ForecastDay> days;
  final DateTime selectedDate;
  final DateTime selectedHour;
  final DateTime today;
  final Language language;
  final ValueChanged<DateTime> onHourSelected;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onGoToBest;

  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFF16A34A);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeDay = days.firstWhere(
      (d) => d.date == selectedDate,
      orElse: () => days.isNotEmpty
          ? days.first
          : ForecastDay(date: selectedDate, rows: const []),
    );
    final rows = activeDay.rows;
    final bestTime = activeDay.bestHour?.time;
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final day in days) ...[
                    _DayChip(
                      label: forecastDayLabel(day.date, today, language),
                      selected: day.date == selectedDate,
                      isDark: isDark,
                      onTap: () => onDaySelected(day.date),
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Draggable timeline
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                void selectFromDx(double dx) {
                  if (rows.isEmpty) return;
                  final clamped = dx.clamp(0.0, width);
                  final index = (clamped / width * rows.length).floor().clamp(
                    0,
                    rows.length - 1,
                  );
                  final t = rows[index].time;
                  if (t != null) onHourSelected(t);
                }

                return GestureDetector(
                  key: const ValueKey('scrubber-track'),
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => selectFromDx(d.localPosition.dx),
                  onHorizontalDragUpdate: (d) =>
                      selectFromDx(d.localPosition.dx),
                  child: SizedBox(
                    height: 56,
                    width: width,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          left: 4,
                          right: 4,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            for (final row in rows)
                              Expanded(
                                child: _ScrubberTick(
                                  hourLabel:
                                      int.parse(row.hour.split(':').first) %
                                              3 ==
                                          0
                                      ? row.hour.split(':').first
                                      : null,
                                  color: _scoreColor(row.score),
                                  selected: row.time == selectedHour,
                                  isBest: row.time == bestTime,
                                  isDark: isDark,
                                  mutedColor: mutedColor,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const ValueKey('go-to-best-hour'),
                onPressed: onGoToBest,
                icon: const Icon(Icons.center_focus_strong_rounded, size: 16),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0F766E),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                label: Text(
                  AppStrings.get('ir_a_mejor_hora', language: language),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF0F766E)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? const Color(0xFF0F766E)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: selected
                ? Colors.white
                : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }
}

class _ScrubberTick extends StatelessWidget {
  const _ScrubberTick({
    required this.hourLabel,
    required this.color,
    required this.selected,
    required this.isBest,
    required this.isDark,
    required this.mutedColor,
  });

  final String? hourLabel;
  final Color color;
  final bool selected;
  final bool isBest;
  final bool isDark;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final dotSize = selected ? 18.0 : (isBest ? 14.0 : 8.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 14,
          child: hourLabel == null
              ? null
              : Text(
                  hourLabel!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                    color: selected ? const Color(0xFF0F766E) : mutedColor,
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              width: selected || isBest ? 3 : 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
      ],
    );
  }
}
