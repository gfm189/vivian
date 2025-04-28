// File: lib/providers/cart_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/product_model.dart';
import '../services/woocommerce_service.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': product.id,
      'name': product.name,
      'price': product.price,
      'image': product.images.isNotEmpty ? product.images[0] : '',
      'quantity': quantity,
    };
  }
}

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];

  final WooCommerceService _wooService = WooCommerceService(
    baseUrl: 'https://vivianwater.com',
    consumerKey: 'ck_ef37137a3182237d24fc9b453cc47f29b6de49bf',
    consumerSecret: 'cs_40f7f340b14b3daec3668383ce80c86847dbca98',
  );

  List<CartItem> get items => _items;

  double get totalAmount {
    return _items.fold(0.0, (sum, item) {
      return sum + (double.tryParse(item.product.price) ?? 0) * item.quantity;
    });
  }

  int get itemCount => _items.length;

  Future<void> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cartData = prefs.getString('cart');

      if (cartData != null && cartData.isNotEmpty) {
        // This is a simplified version. In a real app, you would need to fetch
        // the actual product details from WooCommerce
        // For now, we're just loading the basic cart structure
        notifyListeners();
      }
    } catch (e) {
      print('Error loading cart: $e');
    }
  }

  Future<void> saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> cartData = _items.map((item) => item.toJson()).toList();
      await prefs.setString('cart', json.encode(cartData));
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  void addItem(Product product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }

    saveCart();
    notifyListeners();
  }

  void removeItem(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    saveCart();
    notifyListeners();
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final existingIndex = _items.indexWhere((item) => item.product.id == productId);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity = quantity;
      saveCart();
      notifyListeners();
    }
  }

  void clear() {
    _items = [];
    saveCart();
    notifyListeners();
  }
}