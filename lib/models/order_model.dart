// File: lib/models/order_model.dart

class Order {
  final int id;
  final String status;
  final String total;
  final String dateCreated;
  final Billing billing;
  final Shipping shipping;
  final List<OrderItem> lineItems;
  final Map<String, dynamic> metaData;

  Order({
    required this.id,
    required this.status,
    required this.total,
    required this.dateCreated,
    required this.billing,
    required this.shipping,
    required this.lineItems,
    required this.metaData,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      status: json['status'] ?? '',
      total: json['total'] ?? '0',
      dateCreated: json['date_created'] ?? '',
      billing: Billing.fromJson(json['billing'] ?? {}),
      shipping: Shipping.fromJson(json['shipping'] ?? {}),
      lineItems: json['line_items'] != null
          ? List<OrderItem>.from(
          json['line_items'].map((x) => OrderItem.fromJson(x)))
          : [],
      metaData: json['meta_data'] != null
          ? Map<String, dynamic>.fromEntries(
        (json['meta_data'] as List).map(
              (meta) => MapEntry(meta['key'], meta['value']),
        ),
      )
          : {},
    );
  }

  String? get deliveryDate => metaData['Delivery Date'];
  String? get deliveryTime => metaData['Delivery Time'];
}

class Billing {
  final String firstName;
  final String lastName;
  final String address1;
  final String email;
  final String phone;

  Billing({
    required this.firstName,
    required this.lastName,
    required this.address1,
    required this.email,
    required this.phone,
  });

  factory Billing.fromJson(Map<String, dynamic> json) {
    return Billing(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      address1: json['address_1'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class Shipping {
  final String firstName;
  final String lastName;
  final String address1;

  Shipping({
    required this.firstName,
    required this.lastName,
    required this.address1,
  });

  factory Shipping.fromJson(Map<String, dynamic> json) {
    return Shipping(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      address1: json['address_1'] ?? '',
    );
  }
}

class OrderItem {
  final int id;
  final String name;
  final int productId;
  final int quantity;
  final String total;

  OrderItem({
    required this.id,
    required this.name,
    required this.productId,
    required this.quantity,
    required this.total,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      productId: json['product_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      total: json['total'] ?? '0',
    );
  }
}