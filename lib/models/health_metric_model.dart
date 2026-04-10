/// Matches back-end `HealthMetric` entity.
/// Returned by `GET /api/iot/history/{patientId}`.
class HealthMetricModel {
  final int id;
  final double? heartRate;
  final double? spo2;
  final int? batteryLevel;
  final DateTime? timestamp;
  final bool isCritical;

  HealthMetricModel({
    required this.id,
    this.heartRate,
    this.spo2,
    this.batteryLevel,
    this.timestamp,
    this.isCritical = false,
  });

  factory HealthMetricModel.fromJson(Map<String, dynamic> json) {
    return HealthMetricModel(
      id: json['id'] as int,
      heartRate: (json['heartRate'] as num?)?.toDouble(),
      spo2: (json['spo2'] as num?)?.toDouble(),
      batteryLevel: json['batteryLevel'] as int?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
      // Jackson serializes boolean field `isCritical` as `critical` by default
      // because of the `is` prefix convention. Handle both cases.
      isCritical: json['critical'] as bool? ?? json['isCritical'] as bool? ?? false,
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
