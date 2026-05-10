/// Matches back-end `HourlySummaryResponse` DTO.
/// Returned by `GET /api/iot/summary/hourly/{patientId}?hours=N`.
class HourlySummaryModel {
  final DateTime dateTime;
  final double? avgHeartRate;
  final double? avgSpo2;
  final double? minHeartRate;
  final double? maxHeartRate;
  final double? minSpo2;
  final double? maxSpo2;
  final int readingCount;

  HourlySummaryModel({
    required this.dateTime,
    this.avgHeartRate,
    this.avgSpo2,
    this.minHeartRate,
    this.maxHeartRate,
    this.minSpo2,
    this.maxSpo2,
    this.readingCount = 0,
  });

  factory HourlySummaryModel.fromJson(Map<String, dynamic> json) {
    return HourlySummaryModel(
      dateTime: DateTime.parse(json['dateTime'] as String),
      avgHeartRate: (json['avgHeartRate'] as num?)?.toDouble(),
      avgSpo2: (json['avgSpo2'] as num?)?.toDouble(),
      minHeartRate: (json['minHeartRate'] as num?)?.toDouble(),
      maxHeartRate: (json['maxHeartRate'] as num?)?.toDouble(),
      minSpo2: (json['minSpo2'] as num?)?.toDouble(),
      maxSpo2: (json['maxSpo2'] as num?)?.toDouble(),
      readingCount: (json['readingCount'] as num?)?.toInt() ?? 0,
    );
  }
}
