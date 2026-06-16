import '../rules/rule_severity.dart';

class FlightRuleResult {
  const FlightRuleResult({
    required this.code,
    required this.severity,
    required this.title,
    required this.details,
    this.measuredValue,
    this.threshold,
  });

  final String code;
  final RuleSeverity severity;
  final String title;
  final String details;
  final double? measuredValue;
  final double? threshold;
}
