// lib/widgets/custom_sidebar_menu.dart

import 'package:flutter/material.dart';

class CustomSidebarMenu extends StatelessWidget {
  final String? userName;
  final VoidCallback onHomeTap;
  final VoidCallback onMyOrdersTap;
  final VoidCallback onSavedAddressesTap;
  final VoidCallback onLanguageTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onTermsConditionsTap;
  final VoidCallback onHelpCenterTap;
  final VoidCallback onAboutTap;
  final VoidCallback onRateUsTap;
  final VoidCallback onLogOutTap;
  final VoidCallback onBackTap;

  const CustomSidebarMenu({
    Key? key,
    this.userName,
    required this.onHomeTap,
    required this.onMyOrdersTap,
    required this.onSavedAddressesTap,
    required this.onLanguageTap,
    required this.onSettingsTap,
    required this.onTermsConditionsTap,
    required this.onHelpCenterTap,
    required this.onAboutTap,
    required this.onRateUsTap,
    required this.onLogOutTap,
    required this.onBackTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBackTap,
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // User greeting section - shown only when user is logged in
          if (userName != null && userName!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              color: Colors.blue.shade50,
              child: Column(
                children: [
                  const Text(
                    'Hello!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName!,
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Main menu items
          _buildMenuItem(
            icon: Icons.home_outlined,
            title: 'Home',
            onTap: onHomeTap,
          ),

          _buildMenuItem(
            icon: Icons.shopping_cart_outlined,
            title: 'My Orders',
            onTap: onMyOrdersTap,
            showArrow: true,
          ),

          _buildMenuItem(
            icon: Icons.location_on_outlined,
            title: 'Saved Addresses',
            onTap: onSavedAddressesTap,
            showArrow: true,
          ),

          _buildMenuItem(
            icon: Icons.language,
            title: 'Language',
            trailingText: 'العربية',
            onTap: onLanguageTap,
          ),

          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: onSettingsTap,
            showArrow: true,
          ),

          _buildMenuItem(
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            onTap: onTermsConditionsTap,
            showArrow: true,
          ),

          _buildMenuItem(
            icon: Icons.headset_mic_outlined,
            title: 'Help Center',
            onTap: onHelpCenterTap,
            showArrow: true,
          ),

          _buildMenuItem(
            icon: Icons.info_outline,
            title: 'About Nova',
            onTap: onAboutTap,
            showArrow: true,
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Bottom section items
          _buildMenuItem(
            icon: Icons.star_outline,
            title: 'Rate Us on the App Store',
            onTap: onRateUsTap,
            showArrow: true,
          ),

          _buildMenuItem(
            icon: Icons.logout,
            title: 'Log Out',
            onTap: onLogOutTap,
            showArrow: true,
          ),

          const SizedBox(height: 48),

          // Logo at the bottom
          Center(
            child: Image.asset(
              'assets/images/logo.png', // Make sure you have this file in your assets
              width: 80,
              height: 80,
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showArrow = false,
    String? trailingText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailingText != null)
                Text(
                  trailingText,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              if (showArrow)
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
            ],
          ),
        ),
      ),
    );
  }
}