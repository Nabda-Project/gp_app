/// Matches back-end `PatientResponse` DTO.
/// Returned by `GET /api/doctor/patients/{doctorId}`.
class PatientResponseModel {
  final int id;
  final String fullName;
  final String email;
  final String priority;

  PatientResponseModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.priority,
  });

  factory PatientResponseModel.fromJson(Map<String, dynamic> json) {
    return PatientResponseModel(
      id: json['id'] as int,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      priority: json['priority'] as String? ?? 'MEDIUM',
    );
  }
}
