import 'package:hive/hive.dart';

class UserModel {
  final String id; // Firebase UID (kept for Firebase compatibility)
  final int? backendId; // Back-end PostgreSQL Long ID (needed for API calls)
  final String fullName;
  final String email;
  final String role; // 'Patient' or 'Doctor' (title-case for mobile display)
  final String? phoneNumber;
  final String? licenseNumber;

  UserModel({
    required this.id,
    this.backendId,
    required this.fullName,
    required this.email,
    required this.role,
    this.phoneNumber,
    this.licenseNumber,
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
    );
  }

  /// Create from back-end JSON (User entity returned by POST /api/auth/register).
  /// Back-end role is "PATIENT"/"DOCTOR" (uppercase); we normalise to title-case.
  factory UserModel.fromBackendJson(Map<String, dynamic> json, {String? firebaseUid}) {
    final rawRole = json['role'] as String? ?? 'PATIENT';
    final role = rawRole == 'DOCTOR' ? 'Doctor' : 'Patient';

    return UserModel(
      id: firebaseUid ?? '',
      backendId: json['id'] as int?,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: role,
      phoneNumber: json['phoneNumber'] as String?,
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
  }) {
    return UserModel(
      id: id ?? this.id,
      backendId: backendId ?? this.backendId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      licenseNumber: licenseNumber ?? this.licenseNumber,
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
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(7) // total number of fields
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
      ..write(obj.phoneNumber);
  }
}
