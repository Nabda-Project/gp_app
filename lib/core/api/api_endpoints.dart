/// All back-end REST endpoint paths in one place.
/// Base URL prefix is handled by DioClient.
class ApiEndpoints {
  ApiEndpoints._();

  // ─── Auth ───
  static const String register = '/auth/register';
  static const String login = '/auth/login';

  // ─── User ───
  static const String currentUser = '/user/me';
  static const String updateProfile = '/user/me';
  static const String updateFcmToken = '/user/fcm-token';

  // ─── Doctor ───
  static const String assignPatient = '/doctor/assign';
  static const String removePatient = '/doctor/remove';
  static String doctorPatients(int doctorId) => '/doctor/patients/$doctorId';
  static const String searchByName = '/doctor/search/name';
  static const String searchByPhone = '/doctor/search/phone';

  // ─── IoT / Health Metrics ───
  static String uploadMetric(int patientId) => '/iot/upload/$patientId';
  static String metricHistory(int patientId) => '/iot/history/$patientId';
  static String latestMetric(int patientId) => '/iot/latest/$patientId';
  static String metricSummary(int patientId) => '/iot/summary/$patientId';
  static String hourlySummary(int patientId) =>
      '/iot/summary/hourly/$patientId';

  // ─── Patient ───
  static String patientDoctor(int patientId) => '/patient/doctor/$patientId';

  // ─── Chat ───
  static String chatHistory(int userId1, int userId2) =>
      '/chat/history/$userId1/$userId2';
  static String chatConversations(int userId) => '/chat/conversations/$userId';
  static String chatMarkRead(int senderId, int receiverId) =>
      '/chat/read/$senderId/$receiverId';
  static String chatMarkDelivered(int senderId, int receiverId) =>
      '/chat/deliver/$senderId/$receiverId';

  // ─── Presence ───
  static String presence(int userId) => '/presence/$userId';
  static String presenceHeartbeat(int userId) => '/presence/heartbeat/$userId';

  // ─── Appointments ───
  static const String scheduleAppointment = '/appointments/schedule';
  static String doctorAppointments(int doctorId) =>
      '/appointments/doctor/$doctorId';
  static String nextAppointment(int patientId) =>
      '/appointments/patient/$patientId/next';
  static String updateAppointmentStatus(int appointmentId) =>
      '/appointments/$appointmentId/status';

  // ─── Notifications ───
  static String notifications(int userId, {int page = 0, int size = 20}) =>
      '/notifications/$userId?page=$page&size=$size';
  static String notificationsUnreadCount(int userId) =>
      '/notifications/$userId/unread-count';
  static String notificationMarkRead(int notificationId, int userId) =>
      '/notifications/$notificationId/read/$userId';
  static String notificationsMarkAllRead(int userId) =>
      '/notifications/$userId/read-all';
  static String notificationsMarkChatRead(int userId, int senderId) =>
      '/notifications/$userId/read-chat/$senderId';
  static String notificationsMarkAppointmentsRead(int userId) =>
      '/notifications/$userId/read-appointments';
  static String notificationDelete(int notificationId, int userId) =>
      '/notifications/$notificationId/user/$userId';
  static String notificationDeleteChatNotifications(int userId, int senderId) =>
      '/notifications/$userId/chat/$senderId';
  static String notificationDeleteAll(int userId) =>
      '/notifications/$userId/all';
}
