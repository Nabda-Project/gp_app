class DoctorInfoModel {
  final int id;
  final String fullName;
  final String email;
  final String? profileImageUrl;

  const DoctorInfoModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.profileImageUrl,
  });

  factory DoctorInfoModel.fromJson(Map<String, dynamic> json) {
    return DoctorInfoModel(
      id: json['id'] as int,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}
