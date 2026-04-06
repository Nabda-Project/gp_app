class AppointmentModel {
  final int? id;
  final int doctorId;
  final String doctorName;
  final int patientId;
  final String patientName;
  final DateTime appointmentDate;
  final String? reason;
  final String status;

  AppointmentModel({
    this.id,
    required this.doctorId,
    required this.doctorName,
    required this.patientId,
    required this.patientName,
    required this.appointmentDate,
    this.reason,
    required this.status,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'],
      doctorId: json['doctorId'],
      doctorName: json['doctorName'] ?? '',
      patientId: json['patientId'],
      patientName: json['patientName'] ?? '',
      appointmentDate: DateTime.parse(json['appointmentDate'].toString().endsWith('Z')
          ? json['appointmentDate']
          : '${json['appointmentDate']}Z'),
      reason: json['reason'],
      status: json['status'] ?? 'SCHEDULED',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'patientId': patientId,
      'patientName': patientName,
      'appointmentDate': appointmentDate.toIso8601String(),
      if (reason != null) 'reason': reason,
      'status': status,
    };
  }
}
