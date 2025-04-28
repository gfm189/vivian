// File: lib/services/woocommerce_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../models/order_model.dart';

class WooCommerceService {
  final String baseUrl;
  final String consumerKey;
  final String consumerSecret;

  WooCommerceService({
    required this.baseUrl,
    required this.consumerKey,
    required this.consumerSecret,
  });

  // Headers for authentication
  Map<String, String> get _headers => {
    'Authorization': 'Basic ' + base64Encode(utf8.encode('$consumerKey:$consumerSecret')),
    'Content-Type': 'application/json',
  };

  // Error handling helper
  Exception _handleError(http.Response response) {
    print('API Error: ${response.statusCode} - ${response.body}');
    return Exception('Failed API request with status: ${response.statusCode}, message: ${response.body}');
  }

  // Get all products
  Future<List<Product>> getProducts() async {
    try {
      final url = '$baseUrl/wp-json/wc/v3/products?per_page=100';
      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      print('Error fetching products: $e');
      // Return empty list if API fails
      return [];
    }
  }

  // Get product details
  Future<Product> getProduct(int productId) async {
    try {
      final url = '$baseUrl/wp-json/wc/v3/products/$productId';
      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode == 200) {
        return Product.fromJson(json.decode(response.body));
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      print('Error fetching product details: $e');
      rethrow; // Rethrow to be handled by caller
    }
  }

  // Create an order
  Future<Order> createOrder({
    required String customerName,
    required String address,
    required String phone,
    required String email,
    required String deliveryDate,
    required String deliveryTime,
    required List<LineItem> lineItems,
    String paymentMethod = 'cod',
  }) async {
    final url = '$baseUrl/wp-json/wc/v3/orders';

    final Map<String, dynamic> orderData = {
      'payment_method': paymentMethod,
      'payment_method_title': paymentMethod == 'cod' ? 'Cash on Delivery' : 'Electronic Payment',
      'billing': {
        'first_name': customerName,
        'address_1': address,
        'email': email,
        'phone': phone,
      },
      'shipping': {
        'first_name': customerName,
        'address_1': address,
      },
      'line_items': lineItems.map((item) => {
        'product_id': item.productId,
        'quantity': item.quantity,
      }).toList(),
      'meta_data': [
        {
          'key': 'Delivery Date',
          'value': deliveryDate,
        },
        {
          'key': 'Delivery Time',
          'value': deliveryTime,
        }
      ],
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(orderData),
      );

      if (response.statusCode == 201) {
        return Order.fromJson(json.decode(response.body));
      } else {
        throw _handleError(response);
      }
    } catch (e) {
      print('Error creating order: $e');
      rethrow; // Rethrow to be handled by caller
    }
  }

  // Get available delivery time slots for a specific date
  Future<List<String>> getDeliveryTimeSlots(String date) async {
    // In a real implementation, you would fetch this from your WooCommerce site
    // For now, we'll return hardcoded time slots
    await Future.delayed(Duration(milliseconds: 500)); // Simulating network delay

    return [
      '9:00 AM - 11:00 AM',
      '11:00 AM - 1:00 PM',
      '1:00 PM - 3:00 PM',
      '3:00 PM - 5:00 PM',
      '5:00 PM - 7:00 PM',
    ];
  }
}

// Line item for order creation
class LineItem {
  final int productId;
  final int quantity;

  LineItem({
    required this.productId,
    required this.quantity,
  });
}