import 'package:flutter/material.dart';

const Color _night = Color(0xFF1E293B);
const Color _twilight = Color(0xFFF59E0B);
const Color _day = Color(0xFF38BDF8);
const Color _neutral = Color(0xFF94A3B8);

class DayNightGradient {
  const DayNightGradient({required this.colors, required this.stops});

  final List<Color> colors;
  final List<double> stops;
}

DayNightGradient dayNightGradient({
  required DateTime trackStart,
  required DateTime trackEnd,
  DateTime? sunrise,
  DateTime? sunset,
}) {
  final totalMs = trackEnd.difference(trackStart).inMilliseconds;
  if (sunrise == null || sunset == null || totalMs <= 0) {
    return const DayNightGradient(colors: [_neutral, _neutral], stops: [0, 1]);
  }

  double frac(DateTime t) =>
      (t.difference(trackStart).inMilliseconds / totalMs).clamp(0.0, 1.0);

  // Day band entirely outside the visible track -> solid night.
  if (!sunset.isAfter(trackStart) ||
      !sunrise.isBefore(trackEnd) ||
      !sunset.isAfter(sunrise)) {
    return const DayNightGradient(colors: [_night, _night], stops: [0, 1]);
  }

  final sr = frac(sunrise);
  final ss = frac(sunset);
  const t = 0.04; // transition half-width

  final raw = <(double, Color)>[
    (0.0, _night),
    ((sr - t).clamp(0.0, 1.0), _night),
    (sr, _twilight),
    ((sr + t).clamp(0.0, 1.0), _day),
    ((ss - t).clamp(0.0, 1.0), _day),
    (ss, _twilight),
    ((ss + t).clamp(0.0, 1.0), _night),
    (1.0, _night),
  ];

  final colors = <Color>[];
  final stops = <double>[];
  for (final (s, c) in raw) {
    if (stops.isNotEmpty && s <= stops.last) {
      // At/behind the previous stop after clamping: keep the later band color.
      colors[colors.length - 1] = c;
    } else {
      stops.add(s);
      colors.add(c);
    }
  }
  return DayNightGradient(colors: colors, stops: stops);
}
