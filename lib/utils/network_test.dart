// lib/utils/network_test.dart

import 'package:http/http.dart' as http;

class NetworkTest {
  // Test general internet connectivity
  static Future<bool> testInternetConnection() async {
    try {
      final response = await http.get(Uri.parse('https://www.google.com'));
      print('Internet test status code: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Internet connection test failed: $e');
      return false;
    }
  }

  // Test Unifonic API connectivity with GET request
  static Future<bool> testUnifonic() async {
    try {
      // Simple GET request to check if we can reach Unifonic servers
      final response = await http.get(Uri.parse('https://api.unifonic.com/'));
      print('Unifonic test status code: ${response.statusCode}');
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (e) {
      print('Unifonic connectivity test failed: $e');
      return false;
    }
  }
}