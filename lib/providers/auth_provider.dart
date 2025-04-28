// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:vivianwater/services/auth_service.dart';
import 'package:vivianwater/models/user_model.dart';
import 'package:vivianwater/services/sms_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final SmsService _smsService = SmsService();

  // OTP related fields
  String _currentOtp = '';
  String _phoneNumber = '';
  String get currentOtp => _currentOtp;
  // For development only - determines if we should bypass actual verification
  // Remove or set to false before production release
  final bool _devBypassVerification = false;

  // User data
  User? get currentUser => _authService.currentUser;
  bool get isLoggedIn => _authService.isLoggedIn;

  // Initialize the provider
  Future<void> init() async {
    await _authService.init();
    notifyListeners();
  }

  // Send OTP to the provided phone number
  Future<bool> sendOtp(String phoneNumber) async {
    try {
      // Validate phone number
      if (!_smsService.isValidPhoneNumber(phoneNumber)) {
        return false;
      }

      _phoneNumber = phoneNumber;

      // Generate new OTP
      _currentOtp = _smsService.generateOtp();

      // Actually send the OTP via SMS
      final success = await _smsService.sendOtp(phoneNumber, _currentOtp);

      return success;
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }

  // Verify the OTP entered by the user
  Future<bool> verifyOtp(String enteredOtp) async {
    if (enteredOtp == _currentOtp) {
      // Check if user already exists
      final existingUser = await _authService.findUserByPhone(_phoneNumber);

      if (existingUser != null) {
        // User exists, log them in
        await _authService.setVerifiedUser(existingUser);
        print("User exists and is now logged in: ${existingUser.isRegistered}");
      } else {
        // New user, create a temporary account
        final newUser = User(
          phoneNumber: _phoneNumber,
          isRegistered: false,
        );
        await _authService.setVerifiedUser(newUser);
        print("New temporary user created: ${newUser.phoneNumber}");
      }

      notifyListeners();
      return true;
    }

    return false;
  }

  // Complete the registration with additional user information
  Future<bool> completeRegistration(String name, String email, [String password = '']) async {
    try {
      if (currentUser == null) {
        return false;
      }

      // Create updated user
      final updatedUser = User(
        id: currentUser!.id,
        phoneNumber: currentUser!.phoneNumber,
        name: name,
        email: email,
        isRegistered: true,
        // You can store the password in the metadata if needed
        metadata: password.isNotEmpty ? {'password': password} : null,
      );

      // User already exists in WooCommerce but needs update
      if (currentUser!.id != null) {
        final user = await _authService.updateUser(updatedUser);
        notifyListeners();
        return user != null;
      }
      // New user needs to be created
      else {
        final user = await _authService.createUser(updatedUser, password);
        notifyListeners();
        return user != null;
      }
    } catch (e) {
      print('Error completing registration: $e');
      return false;
    }
  }

  // Log out current user
  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }
}