/// Matches back-end `MeasurementResponse` DTO.
/// Returned by `GET /api/iot/history/{patientId}` and `GET /api/iot/latest/{patientId}`.
class HealthMetricModel {
  final int id;
  final double? heartRate;
  final double? spo2;
  final int? batteryLevel;
  final DateTime? timestamp;
  final bool isCritical;
  /// Doctor/system priority computed by backend (CRITICAL, HIGH, MEDIUM, NORMAL, LOW).
  final String? priority;
  /// Patient-facing health status computed by backend (CRITICAL, WARNING, NORMAL, UNKNOWN).
  final String? healthStatus;

  HealthMetricModel({
    required this.id,
    this.heartRate,
    this.spo2,
    this.batteryLevel,
    this.timestamp,
    this.isCritical = false,
    this.priority,
    this.healthStatus,
  });

  factory HealthMetricModel.fromJson(Map<String, dynamic> json) {
    // Backend sends timestamp as 'measuredAt'; handle both names for safety.
    final String? tsRaw =
        (json['measuredAt'] ?? json['timestamp']) as String?;
    return HealthMetricModel(
      id: json['id'] as int,
      heartRate: (json['heartRate'] as num?)?.toDouble(),
      spo2: (json['spo2'] as num?)?.toDouble(),
      batteryLevel: json['batteryLevel'] as int?,
      timestamp: tsRaw != null ? DateTime.tryParse(tsRaw) : null,
      // Jackson serializes boolean field `isCritical` as `critical` by default
      // because of the `is` prefix convention. Handle both cases.
      isCritical: json['critical'] as bool? ?? json['isCritical'] as bool? ?? false,
      priority: json['priority'] as String?,
      healthStatus: json['healthStatus'] as String?,
    );
  }

  /// Human-readable heart rate string.
  String get heartRateDisplay =>
      heartRate != null ? heartRate!.toStringAsFixed(0) : '--';

  /// Human-readable SpO2 string.
  String get spo2Display =>
      spo2 != null ? spo2!.toStringAsFixed(0) : '--';

  /// Human-readable battery level string.
  String get batteryLevelDisplay =>
      batteryLevel != null ? batteryLevel!.toString() : '--';
}
