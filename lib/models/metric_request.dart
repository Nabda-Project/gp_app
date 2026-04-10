/// Matches back-end `MetricRequest` DTO.
/// Sent to `POST /api/iot/upload/{patientId}`.
class MetricRequest {
  final double heartRate;
  final double spo2;
  final int batteryLevel;

  MetricRequest({
    required this.heartRate,
    required this.spo2,
    required this.batteryLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'heartRate': heartRate,
      'spo2': spo2,
      'batteryLevel': batteryLevel,
    };
  }
}
