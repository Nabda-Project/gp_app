/// Matches back-end `MetricRequest` DTO.
/// Sent to `POST /api/iot/upload/{patientId}`.
class MetricRequest {
  final double heartRate;
  final double spo2;
  final double bodyTemp;

  MetricRequest({
    required this.heartRate,
    required this.spo2,
    required this.bodyTemp,
  });

  Map<String, dynamic> toJson() {
    return {
      'heartRate': heartRate,
      'spo2': spo2,
      'bodyTemp': bodyTemp,
    };
  }
}
