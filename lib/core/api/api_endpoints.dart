/// All back-end REST endpoint paths in one place.
/// Base URL prefix is handled by DioClient.
class ApiEndpoints {
  ApiEndpoints._();

  // ─── Auth ───
  static const String register = '/auth/register';
  static const String login = '/auth/login';

  // ─── Doctor ───
  static const String assignPatient = '/doctor/assign';
  static const String removePatient = '/doctor/remove';
  static String doctorPatients(int doctorId) => '/doctor/patients/$doctorId';
  static const String searchByName = '/doctor/search/name';
  static const String searchByPhone = '/doctor/search/phone';

  // ─── IoT / Health Metrics ───
  static String uploadMetric(int patientId) => '/iot/upload/$patientId';
  static String metricHistory(int patientId) => '/iot/history/$patientId';

  // ─── Patient ───
  static String patientDoctor(int patientId) => '/patient/doctor/$patientId';

  // ─── Chat ───
  static String chatHistory(int userId1, int userId2) =>
      '/chat/history/$userId1/$userId2';
  static String chatConversations(int userId) =>
      '/chat/conversations/$userId';
  static String chatMarkRead(int senderId, int receiverId) =>
      '/chat/read/$senderId/$receiverId';
  static String chatMarkDelivered(int senderId, int receiverId) =>
      '/chat/deliver/$senderId/$receiverId';

  // ─── Presence ───
  static String presence(int userId) => '/presence/$userId';
  static String presenceHeartbeat(int userId) => '/presence/heartbeat/$userId';
}
