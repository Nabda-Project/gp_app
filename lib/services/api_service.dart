import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';

class ApiService {
  static Future<String> testConnection() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.baseUrl)).timeout(const Duration(seconds: 4));
      // As long as we receive an HTTP response (even 401, 403, 404, 500), the server is physically up and responding.
      return 'Success';
    } catch (e) {
      return 'Exception: $e';
    }
  }
}
