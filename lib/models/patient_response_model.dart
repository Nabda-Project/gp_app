/// Matches back-end `PatientResponse` DTO.
/// Returned by `GET /api/doctor/patients/{doctorId}`.
class PatientResponseModel {
  final int id;
  final String fullName;
  final String email;
  final String priority;
  final String? profileImageUrl;
  final String? gender;
  final String? dateOfBirth;
  final double? height;
  final double? weight;

  PatientResponseModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.priority,
    this.profileImageUrl,
    this.gender,
    this.dateOfBirth,
    this.height,
    this.weight,
  });

  factory PatientResponseModel.fromJson(Map<String, dynamic> json) {
    return PatientResponseModel(
      id: json['id'] as int,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      priority: json['priority'] as String? ?? 'MEDIUM',
      profileImageUrl: json['profileImageUrl'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
    );
  }

  /// Calculate age from dateOfBirth string (ISO format: yyyy-MM-dd).
  int? get age {
    if (dateOfBirth == null) return null;
    final dob = DateTime.tryParse(dateOfBirth!);
    if (dob == null) return null;
    final now = DateTime.now();
    int years = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      years--;
    }
    return years;
  }
}
