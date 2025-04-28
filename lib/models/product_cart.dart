// File: lib/models/product_cart.dart
import '../services/woocommerce_service.dart';
import '../utils/service_provider.dart';
import '../models/product_model.dart';

class ProductCart {
  // Use the helper function to get a properly initialized service
  final WooCommerceService wooService = getWooCommerceService();

  // Rest of your code...

  // Example method
  Future<List<Product>> getProducts() async {
    return await wooService.getProducts();
  }
}