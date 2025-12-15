import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';

class ApiService {
  static Future<String> testConnection() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.baseUrl));
      if (response.statusCode == 200) {
        return response.body;
      } else {
        return 'Error: ${response.statusCode}';
      }
    } catch (e) {
      return 'Exception: $e';
    }
  }
}
