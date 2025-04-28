// lib/models/user_model.dart

class User {
  final int? id;
  final String phoneNumber;
  final String? name;
  final String? email;
  final bool isRegistered;
  final Map<String, dynamic>? metadata;

  User({
    this.id,
    required this.phoneNumber,
    this.name,
    this.email,
    this.isRegistered = false,
    this.metadata,
  });

  // Create user from WooCommerce JSON response
  factory User.fromJson(Map<String, dynamic> json) {
    // Extract phone number from billing or meta data
    String phone = '';
    if (json['billing'] != null && json['billing']['phone'] != null) {
      phone = json['billing']['phone'];
    } else if (json['meta_data'] != null) {
      final phoneData = (json['meta_data'] as List).firstWhere(
            (meta) => meta['key'] == 'phone_number',
        orElse: () => {'value': ''},
      );
      phone = phoneData['value'] ?? '';
    } else if (json['phoneNumber'] != null) {
      // Direct from our saved map
      phone = json['phoneNumber'];
    }

    return User(
      id: json['id'],
      phoneNumber: phone,
      name: json['first_name'] != null && json['last_name'] != null
          ? '${json['first_name']} ${json['last_name']}'
          : json['name'] ?? json['username'] ?? '',
      email: json['email'],
      isRegistered: json['isRegistered'] ?? true,
      metadata: json['metadata'],
    );
  }

  // Convert user to JSON for creating/updating in WooCommerce
  Map<String, dynamic> toJson() {
    // Handle null name safely and extract first/last name
    String firstName = '';
    String lastName = '';

    if (name != null && name!.isNotEmpty) {
      List<String> nameParts = name!.split(' ');
      firstName = nameParts[0];
      lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    }

    Map<String, dynamic> result = {
      if (id != null) 'id': id,
      'username': phoneNumber,
      'first_name': firstName,
      'last_name': lastName,
      'email': email ?? '',
      'billing': {
        'phone': phoneNumber,
        'first_name': firstName,
        'last_name': lastName,
        'email': email ?? '',
      },
      'meta_data': [
        {
          'key': 'phone_number',
          'value': phoneNumber,
        }
      ],
    };

    // Add metadata if available
    if (metadata != null && metadata!.isNotEmpty) {
      metadata!.forEach((key, value) {
        result['meta_data'].add({
          'key': key,
          'value': value,
        });
      });
    }

    return result;
  }
}