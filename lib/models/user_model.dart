import 'package:hive/hive.dart';

class UserModel {
  final String id; // Firebase UID (kept for Firebase compatibility)
  final int? backendId; // Back-end PostgreSQL Long ID (needed for API calls)
  final String fullName;
  final String email;
  final String role; // 'Patient' or 'Doctor' (title-case for mobile display)
  final String? phoneNumber;
  final String? licenseNumber;
  final DateTime? dateOfBirth;
  final String? gender;
  final double? height; // in cm
  final double? weight; // in kg
  final String? profileImageUrl; // URL or Base64 data URI of the user's profile image

  UserModel({
    required this.id,
    this.backendId,
    required this.fullName,
    required this.email,
    required this.role,
    this.phoneNumber,
    this.licenseNumber,
    this.dateOfBirth,
    this.gender,
    this.height,
    this.weight,
    this.profileImageUrl,
  });

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'backendId': backendId,
      'fullName': fullName,
      'email': email,
      'role': role,
      'phoneNumber': phoneNumber,
      'licenseNumber': licenseNumber,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'height': height,
      'weight': weight,
      'profileImageUrl': profileImageUrl,
    };
  }

  /// Create from Map (Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      backendId: map['backendId'] as int?,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'Patient',
      phoneNumber: map['phoneNumber'] as String?,
      licenseNumber: map['licenseNumber'] as String?,
      dateOfBirth: map['dateOfBirth'] != null ? DateTime.tryParse(map['dateOfBirth'] as String) : null,
      gender: map['gender'] as String?,
      height: (map['height'] as num?)?.toDouble(),
      weight: (map['weight'] as num?)?.toDouble(),
      profileImageUrl: map['profileImageUrl'] as String?,
    );
  }

  /// Create from back-end JSON.
  /// Handles both [RegisterResponse] (uses "name") and [UserResponse] (uses "fullName").
  /// Back-end role is "PATIENT"/"DOCTOR" (uppercase); we normalise to title-case.
  factory UserModel.fromBackendJson(Map<String, dynamic> json, {String? firebaseUid}) {
    final rawRole = json['role'] as String? ?? 'PATIENT';
    final role = rawRole == 'DOCTOR' ? 'Doctor' : 'Patient';

    // RegisterResponse → 'name'; UserResponse / fetchCurrentUser → 'fullName'
    final fullName = (json['fullName'] ?? json['name']) as String? ?? '';

    return UserModel(
      id: firebaseUid ?? '',
      backendId: json['id'] as int?,
      fullName: fullName,
      email: json['email'] as String? ?? '',
      role: role,
      phoneNumber: json['phoneNumber'] as String?,
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.tryParse(json['dateOfBirth'] as String) : null,
      gender: json['gender'] as String?,
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }

  /// Convert mobile role to back-end enum format.
  String get backendRole => role == 'Doctor' ? 'DOCTOR' : 'PATIENT';

  /// Copy with overrides.
  UserModel copyWith({
    String? id,
    int? backendId,
    String? fullName,
    String? email,
    String? role,
    String? phoneNumber,
    String? licenseNumber,
    DateTime? dateOfBirth,
    String? gender,
    double? height,
    double? weight,
    String? profileImageUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      backendId: backendId ?? this.backendId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String,
      fullName: fields[1] as String,
      email: fields[2] as String,
      role: fields[3] as String,
      licenseNumber: fields[4] as String?,
      backendId: fields.containsKey(5) ? fields[5] as int? : null,
      phoneNumber: fields.containsKey(6) ? fields[6] as String? : null,
      dateOfBirth: fields.containsKey(7) ? fields[7] as DateTime? : null,
      gender: fields.containsKey(8) ? fields[8] as String? : null,
      height: fields.containsKey(9) ? (fields[9] as num?)?.toDouble() : null,
      weight: fields.containsKey(10) ? (fields[10] as num?)?.toDouble() : null,
      profileImageUrl: fields.containsKey(11) ? fields[11] as String? : null,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(12) // total number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fullName)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.role)
      ..writeByte(4)
      ..write(obj.licenseNumber)
      ..writeByte(5)
      ..write(obj.backendId)
      ..writeByte(6)
      ..write(obj.phoneNumber)
      ..writeByte(7)
      ..write(obj.dateOfBirth)
      ..writeByte(8)
      ..write(obj.gender)
      ..writeByte(9)
      ..write(obj.height)
      ..writeByte(10)
      ..write(obj.weight)
      ..writeByte(11)
      ..write(obj.profileImageUrl);
  }
}
