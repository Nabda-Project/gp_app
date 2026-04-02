/// Matches back-end `RegisterRequest` DTO.
/// Sent to `POST /api/auth/register`.
class RegisterRequest {
  final String fullName;
  final String email;
  final String password;
  final String phoneNumber;
  final String role; // "PATIENT" or "DOCTOR" (uppercase to match back-end enum)

  RegisterRequest({
    required this.fullName,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'password': password,
      'phoneNumber': phoneNumber,
      'role': role,
    };
  }
}
