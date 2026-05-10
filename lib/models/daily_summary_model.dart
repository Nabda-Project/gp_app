/// Matches back-end `DailySummaryResponse` DTO.
/// Returned by `GET /api/iot/summary/{patientId}?days=N`.
class DailySummaryModel {
  final DateTime date;
  final double? avgHeartRate;
  final double? avgSpo2;
  final double? minHeartRate;
  final double? maxHeartRate;
  final double? minSpo2;
  final double? maxSpo2;
  final int readingCount;

  DailySummaryModel({
    required this.date,
    this.avgHeartRate,
    this.avgSpo2,
    this.minHeartRate,
    this.maxHeartRate,
    this.minSpo2,
    this.maxSpo2,
    this.readingCount = 0,
  });

  factory DailySummaryModel.fromJson(Map<String, dynamic> json) {
    return DailySummaryModel(
      date: DateTime.parse(json['date'] as String),
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
