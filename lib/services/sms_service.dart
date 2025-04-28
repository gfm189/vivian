// lib/services/sms_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class SmsService {
  // WordPress site URL
  final String baseUrl = 'https://vivianwater.com';

  // Send OTP via WordPress REST API
  Future<bool> sendOtp(String phoneNumber, String otp) async {
    try {
      // Format the phone number
      String formattedNumber = phoneNumber;
      if (!formattedNumber.startsWith('966')) {
        formattedNumber = '966$phoneNumber';
      }

      // Create the WordPress API endpoint URL
      final uri = Uri.parse('$baseUrl/wp-json/vivian/v1/send-otp');

      // Request data
      final requestData = {
        'phone_number': formattedNumber,
        'otp_code': otp
      };

      // Make the API call to WordPress
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      // Parse response
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      }

      return false;
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }

  // Generate OTP code
  String generateOtp() {
    // Generate a random 6-digit code for production
    return (100000 + DateTime.now().millisecond * 900).toString();
  }

  // Basic validation
  bool isValidPhoneNumber(String phoneNumber) {
    return phoneNumber.length >= 9;
  }
}