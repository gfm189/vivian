// lib/services/delivery_date_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class DeliveryDateService {
  final String _baseUrl;
  final String _consumerKey;
  final String _consumerSecret;

  DeliveryDateService()
      : _baseUrl = 'https://vivianwater.com',
        _consumerKey = 'ck_ef37137a3182237d24fc9b453cc47f29b6de49bf',
        _consumerSecret = 'cs_40f7f340b14b3daec3668383ce80c86847dbca98';

  // Get available delivery dates from the plugin
  Future<List<Map<String, dynamic>>> getAvailableDeliveryDates() async {
    try {
      // Try different endpoints that might work with the plugin
      // Option 1: Standard plugin endpoint (most likely)
      final response = await http.get(
        Uri.parse('$_baseUrl/wp-json/order-delivery-date/v1/get-delivery-dates'),
        headers: {
          'Authorization': 'Basic ' +
              base64Encode(utf8.encode('$_consumerKey:$_consumerSecret')),
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('Successfully fetched dates from plugin: ${response.body}');
        final data = json.decode(response.body);

        // Handle different possible response formats
        if (data is List) {
          return data.map((item) => item as Map<String, dynamic>).toList();
        } else if (data is Map) {
          // Some plugins return dates as a map with date strings as keys
          List<Map<String, dynamic>> result = [];
          data.forEach((key, value) {
            if (value is Map) {
              final Map<String, dynamic> dateInfo = Map<String, dynamic>.from(value);
              dateInfo['date'] = key;
              result.add(dateInfo);
            }
          });
          return result;
        }
      }

      // If the first endpoint fails, try an alternative endpoint
      final altResponse = await http.get(
        Uri.parse('$_baseUrl/wp-json/wc/v3/orders/delivery-dates'),
        headers: {
          'Authorization': 'Basic ' +
              base64Encode(utf8.encode('$_consumerKey:$_consumerSecret')),
          'Content-Type': 'application/json',
        },
      );

      if (altResponse.statusCode == 200) {
        print('Successfully fetched dates from alternative endpoint: ${altResponse.body}');
        final data = json.decode(altResponse.body);
        if (data is List) {
          return data.map((item) => item as Map<String, dynamic>).toList();
        }
      }

      // If all API calls fail, use sample dates
      print('Failed to get dates from API, using sample dates');
      return _generateSampleDates();
    } catch (e) {
      print('Exception getting delivery dates: $e');
      return _generateSampleDates();
    }
  }

  // Generate sample delivery dates (fallback if API is not available)
  List<Map<String, dynamic>> _generateSampleDates() {
    List<Map<String, dynamic>> dates = [];
    DateTime now = DateTime.now();

    // Generate dates for the next 14 days
    for (int i = 1; i <= 14; i++) {
      DateTime date = now.add(Duration(days: i));

      // Skip weekends (customize as needed based on your delivery rules)
      if (date.weekday == 6 || date.weekday == 7) {
        continue;
      }

      dates.add({
        'date': date.toIso8601String().split('T')[0],
        'formatted_date': '${_getDayName(date.weekday)} ${date.day}-${date.month}',
        'available': true,
      });
    }

    return dates;
  }

  // Helper method to get day name from weekday number
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }

  // Get time slots for a specific date
  Future<List<String>> getAvailableTimeSlots(String date) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wp-json/order-delivery-date/v1/get-time-slots?date=$date'),
        headers: {
          'Authorization': 'Basic ' +
              base64Encode(utf8.encode('$_consumerKey:$_consumerSecret')),
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Time slots data: $data');

        if (data is List) {
          return data.map((slot) => slot.toString()).toList();
        } else if (data is Map) {
          // Some plugins return time slots with keys
          return data.values.map((slot) => slot.toString()).toList();
        }
      }

      // Fallback time slots
      return _getDefaultTimeSlots();
    } catch (e) {
      print('Error fetching time slots: $e');
      return _getDefaultTimeSlots();
    }
  }

  // Default time slots as fallback
  List<String> _getDefaultTimeSlots() {
    return [
      '9:00 AM - 12:00 PM',
      '12:00 PM - 3:00 PM',
      '3:00 PM - 6:00 PM',
      '6:00 PM - 9:00 PM',
    ];
  }

  // Add the selected delivery date to the order
  Future<void> addDeliveryDateToOrder(int orderId, String deliveryDate, String timeSlot) async {
    try {
      // This would update the order with the selected delivery date and time
      final response = await http.post(
        Uri.parse('$_baseUrl/wp-json/wc/v3/orders/$orderId'),
        headers: {
          'Authorization': 'Basic ' +
              base64Encode(utf8.encode('$_consumerKey:$_consumerSecret')),
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'meta_data': [
            {
              'key': '_orddd_timestamp',
              'value': deliveryDate,
            },
            {
              'key': '_orddd_time_slot',
              'value': timeSlot,
            }
          ]
        }),
      );

      if (response.statusCode != 200) {
        print('Error adding delivery date to order: ${response.statusCode}');
        throw Exception('Failed to add delivery date to order');
      }
    } catch (e) {
      print('Exception adding delivery date to order: $e');
      throw Exception('Failed to add delivery date to order: $e');
    }
  }
}