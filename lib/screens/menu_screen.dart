// lib/screens/menu_screen.dart

import 'package:flutter/material.dart';
import '../widgets/custom_sidebar_menu.dart';

class MenuScreen extends StatelessWidget {
  final String? userName; // Will be null if user is not logged in

  const MenuScreen({
    Key? key,
    this.userName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomSidebarMenu(
      userName: userName,
      onHomeTap: () {
        Navigator.pop(context);
        // Navigate to Home screen
      },
      onMyOrdersTap: () {
        Navigator.pop(context);
        // Navigate to My Orders screen
      },
      onSavedAddressesTap: () {
        Navigator.pop(context);
        // Navigate to Saved Addresses screen
      },
      onLanguageTap: () {
        // Show language dialog or switch language
      },
      onSettingsTap: () {
        Navigator.pop(context);
        // Navigate to Settings screen
      },
      onTermsConditionsTap: () {
        Navigator.pop(context);
        // Navigate to Terms & Conditions screen
      },
      onHelpCenterTap: () {
        Navigator.pop(context);
        // Navigate to Help Center screen
      },
      onAboutTap: () {
        Navigator.pop(context);
        // Navigate to About screen
      },
      onRateUsTap: () {
        // Open app store rating
      },
      onLogOutTap: () {
        // Show logout confirmation dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Log Out'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close menu
                  // Implement logout functionality
                },
                child: const Text('LOG OUT'),
              ),
            ],
          ),
        );
      },
      onBackTap: () {
        Navigator.pop(context);
      },
    );
  }
}