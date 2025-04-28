// lib/services/auth_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  // WooCommerce API information
  final String _baseUrl = 'https://vivianwater.com/wp-json/wc/v3';
  final String _consumerKey = 'ck_ef37137a3182237d24fc9b453cc47f29b6de49bf';
  final String _consumerSecret = 'cs_40f7f340b14b3daec3668383ce80c86847dbca98';

  // Local storage keys
  final String _userKey = 'user_data';

  // Cached user data
  User? _currentUser;

  // Add an unnamed constructor
  AuthService();

  // Getter for current user
  User? get currentUser => _currentUser;

  // Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  // Initialize the service - load user from local storage
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);

    if (userData != null) {
      try {
        final userMap = jsonDecode(userData);
        _currentUser = User.fromJson(userMap);
      } catch (e) {
        print('Error decoding stored user: $e');
        _currentUser = null;
      }
    }
  }

  // Find a user by phone number in WooCommerce
  Future<User?> findUserByPhone(String phoneNumber) async {
    try {
      // Format the phone number for search
      String formattedPhone = phoneNumber;
      if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+$phoneNumber';
      }

      // Search for customers with this phone number
      final response = await http.get(
        Uri.parse('$_baseUrl/customers?phone=$formattedPhone'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> customers = jsonDecode(response.body);

        if (customers.isNotEmpty) {
          // Found a user with this phone number
          final customerData = customers[0];

          return User(
            id: int.tryParse(customerData['id'].toString()),
            name: '${customerData['first_name']} ${customerData['last_name']}',
            email: customerData['email'],
            phoneNumber: phoneNumber,
            isRegistered: true,
          );
        }
      } else {
        print('Error searching for user: ${response.statusCode} - ${response.body}');
      }

      // No user found with this phone number
      return null;
    } catch (e) {
      print('Exception searching for user: $e');
      return null;
    }
  }

  // Create a new user in WooCommerce
  Future<User?> createUser(User user, [String password = '']) async {
    try {
      // Split name into first and last name
      String firstName = '';
      String lastName = '';

      if (user.name != null && user.name!.isNotEmpty) {
        final nameParts = user.name!.split(' ');
        firstName = nameParts.first;
        if (nameParts.length > 1) {
          lastName = nameParts.skip(1).join(' ');
        }
      }

      // Prepare customer data for WooCommerce
      final Map<String, dynamic> customerData = {
        'email': user.email,
        'first_name': firstName,
        'last_name': lastName,
        'phone': user.phoneNumber,
        'username': user.phoneNumber, // Use phone as username
        'password': password.isNotEmpty ? password : user.phoneNumber, // Use phone as password if none provided
        'billing': {
          'phone': user.phoneNumber,
          'email': user.email,
          'first_name': firstName,
          'last_name': lastName,
        },
        'shipping': {
          'phone': user.phoneNumber,
          'first_name': firstName,
          'last_name': lastName,
        },
        'meta_data': [
          {
            'key': 'phone_number',
            'value': user.phoneNumber,
          },
          {
            'key': 'phone_verified',
            'value': 'true',
          }
        ],
      };

      // Create the customer in WooCommerce
      final response = await http.post(
        Uri.parse('$_baseUrl/customers'),
        headers: _getAuthHeaders(),
        body: jsonEncode(customerData),
      );

      if (response.statusCode == 201) {
        final createdCustomer = jsonDecode(response.body);
        final newUser = User(
          id: int.tryParse(createdCustomer['id'].toString()),
          name: user.name,
          email: user.email,
          phoneNumber: user.phoneNumber,
          isRegistered: true,
        );

        // Save to local storage
        await _saveUserToLocalStorage(newUser);

        return newUser;
      } else {
        print('Error creating user: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception creating user: $e');
      return null;
    }
  }

  // Update an existing user in WooCommerce
  Future<User?> updateUser(User user) async {
    try {
      if (user.id == null) {
        return null;
      }

      // Split name into first and last name
      String firstName = '';
      String lastName = '';

      if (user.name != null && user.name!.isNotEmpty) {
        final nameParts = user.name!.split(' ');
        firstName = nameParts.first;
        if (nameParts.length > 1) {
          lastName = nameParts.skip(1).join(' ');
        }
      }

      // Prepare customer data for WooCommerce
      final Map<String, dynamic> customerData = {
        'email': user.email,
        'first_name': firstName,
        'last_name': lastName,
        'phone': user.phoneNumber,
        'billing': {
          'phone': user.phoneNumber,
          'email': user.email,
          'first_name': firstName,
          'last_name': lastName,
        },
        'shipping': {
          'phone': user.phoneNumber,
          'first_name': firstName,
          'last_name': lastName,
        },
        'meta_data': [
          {
            'key': 'phone_number',
            'value': user.phoneNumber,
          },
          {
            'key': 'phone_verified',
            'value': 'true',
          }
        ],
      };

      // Update the customer in WooCommerce
      final response = await http.put(
        Uri.parse('$_baseUrl/customers/${user.id}'),
        headers: _getAuthHeaders(),
        body: jsonEncode(customerData),
      );

      if (response.statusCode == 200) {
        final updatedCustomer = jsonDecode(response.body);
        final updatedUser = User(
          id: int.tryParse(updatedCustomer['id'].toString()),
          name: user.name,
          email: user.email,
          phoneNumber: user.phoneNumber,
          isRegistered: true,
        );

        // Save to local storage
        await _saveUserToLocalStorage(updatedUser);

        return updatedUser;
      } else {
        print('Error updating user: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception updating user: $e');
      return null;
    }
  }

  // Set the current user after OTP verification
  Future<void> setVerifiedUser(User user) async {
    _currentUser = user;
    await _saveUserToLocalStorage(user);
  }

  // Logout the current user
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // Save user to local storage
  Future<void> _saveUserToLocalStorage(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userMap = {
        'id': user.id,
        'phoneNumber': user.phoneNumber,
        'name': user.name,
        'email': user.email,
        'isRegistered': user.isRegistered,
      };

      await prefs.setString(_userKey, jsonEncode(userMap));
      _currentUser = user;
    } catch (e) {
      print('Error saving user to local storage: $e');
    }
  }

  // Get auth headers for WooCommerce API
  Map<String, String> _getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Basic ${base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'))}',
    };
  }
}