# Wind Charts & Trends MVP Spec

## Objective

Add interactive line charts showing wind speed, gust speed, and temperature trends over 1-day, 3-day, 7-day, and 15-day ranges. Help pilots understand wind patterns and plan missions during optimal windows.

## Data sources (existing)

- **Open-Meteo hourly forecast**: Already fetched by `WeatherSession`
- **Mock hourly forecast**: `MockFlightData.forecastSnapshots()`
- **Drone profile limits**: Wind/gust thresholds from `MockFlightData.droneProfile`

## What's new

1. **Wind Chart Widget**
   - Line chart with time on X-axis, wind/gust speed on Y-axis
   - Separate series for wind speed (blue), gust speed (orange)
   - Reference lines showing effective limits (green ok, yellow warning, red blocked)
   - Toggle between wind speed, gust speed, and temperature charts
   - Responsive sizing (fills container width, constrained height)

2. **Time Range Selector**
   - Buttons for 1-day, 3-day, 7-day, 15-day views
   - Active button highlighted
   - Charts update instantly on selection

3. **Chart Features**
   - X-axis: Hourly timestamps (format: HH:mm or date + HH:mm depending on range)
   - Y-axis: Speed (km/h) or temperature (°C)
   - Touch interactions: tap to see tooltip with exact values
   - Legend showing series (Wind, Gust, Temp)
   - Grid for easy reading

4. **Stats Card Below Chart**
   - Min/max values for selected range
   - Average wind speed
   - Best hour (lowest wind) in range
   - Worst hour (highest gust) in range

5. **Data Generation**
   - Use existing forecast snapshots from Open-Meteo or mock data
   - Extend forecast to 15 days if not available (mock or estimate)
   - Filter by selected time range

## Commands

```powershell
flutter pub add fl_chart
dart format lib test docs
flutter test
flutter analyze
```

## Project structure

```text
lib/
  domain/
    models/
      wind_chart_data.dart               ← new: chart data model
  features/
    wind/
      presentation/
        pages/
          wind_chart_page.dart           ← new: full screen chart
        widgets/
          wind_trend_chart.dart          ← new: fl_chart wrapper
          time_range_selector.dart       ← new: 1d/3d/7d/15d buttons
          wind_stats_card.dart           ← new: min/max/avg stats
```

Test structure:

```text
test/
  domain/
    models/
      wind_chart_data_test.dart         ← new: data aggregation tests
  features/
    wind/
      presentation/
        widgets/
          wind_trend_chart_test.dart    ← new: chart rendering tests
```

## Testing strategy

1. **Wind Chart Data Tests**
   - Aggregate forecast snapshots into hourly buckets
   - Calculate min/max/avg for a time range
   - Find best/worst hours correctly

2. **Chart Widget Tests**
   - Verify line chart renders with correct data points
   - Verify reference lines match drone profile limits
   - Verify touch interactions show correct tooltips

3. **Time Range Tests**
   - Verify 1d shows last 24 hours
   - Verify 3d shows last 72 hours
   - Verify 7d and 15d work correctly

## Boundaries

- **No real-time data**: Charts show forecast only, not live conditions.
- **No download/export**: Charts stay in-app for now.
- **No custom ranges**: Fixed 1/3/7/15 day options only.
- **No offline sync**: Charts require internet if using real data.
- **Free chart library**: Use fl_chart (open-source, no API keys).

## Dependencies

```yaml
fl_chart: ^0.69.0  # Popular Flutter charting library
```

## Success criteria

- [ ] Line chart renders with wind/gust/temp data.
- [ ] Time range selector switches views (1d/3d/7d/15d).
- [ ] Reference lines show effective limits (ok/warning/blocked).
- [ ] Stats card shows min/max/avg/best/worst correctly.
- [ ] Charts work with both mock and real Open-Meteo data.
- [ ] Touch tooltip shows exact values on tap.
- [ ] All tests pass, code formatted, analyze clean.
- [ ] No secrets or build outputs staged.

## Open questions

1. Should charts show wind rose (direction) or just speed/gust?
2. Should we add a "Best Days" widget highlighting optimal windows?
3. Should precipitation probability be overlaid on wind chart?
4. Should we allow exporting chart as image for briefing pilots?
5. Should we cache forecast data locally to enable offline charts?

## Acceptance criteria

- Wind trend charts provide clear visibility into patterns over 1-15 days.
- Pilots can quickly identify best flying windows by visual inspection.
- Charts respect drone profile limits (visual reference lines).
- Data updates automatically when location or weather source changes.
