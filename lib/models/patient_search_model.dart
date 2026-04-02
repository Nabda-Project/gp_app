/// Matches back-end `PatientSearchResponse` DTO.
/// Returned by `GET /api/doctor/search?doctorId=X&query=Y`.
class PatientSearchModel {
  final int id;
  final String fullName;
  final String email;
  final String? phoneNumber;

  PatientSearchModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
  });

  factory PatientSearchModel.fromJson(Map<String, dynamic> json) {
    return PatientSearchModel(
      id: json['id'] as int,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
    );
  }
}
