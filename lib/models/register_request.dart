/// Matches back-end `RegisterRequest` DTO.
/// Sent to `POST /api/auth/register`.
class RegisterRequest {
  final String fullName;
  final String email;
  final String password;
  final String phoneNumber;
  final String role; // "PATIENT" or "DOCTOR" (uppercase to match back-end enum)
  final DateTime dateOfBirth;
  final String gender; // "MALE" or "FEMALE"
  final double? height; // in cm (patients only)
  final double? weight; // in kg (patients only)

  RegisterRequest({
    required this.fullName,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.role,
    required this.dateOfBirth,
    required this.gender,
    this.height,
    this.weight,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'fullName': fullName,
      'email': email,
      'password': password,
      'phoneNumber': phoneNumber,
      'role': role,
      'dateOfBirth': "${dateOfBirth.year.toString().padLeft(4, '0')}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}",
      'gender': gender,
    };
    if (height != null) map['height'] = height;
    if (weight != null) map['weight'] = weight;
    return map;
  }
}
