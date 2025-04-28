// lib/config/api_config.dart

class WooConfig {
  // Your WooCommerce API credentials
  static const String consumerKey = 'ck_ef37137a3182237d24fc9b453cc47f29b6de49bf';
  static const String consumerSecret = 'cs_40f7f340b14b3daec3668383ce80c86847dbca98';
  static const String baseUrl = 'https://vivianwater.com';

  // WooCommerce REST API endpoints
  static const String productsUrl = '$baseUrl/wp-json/wc/v3/products';
  static const String categoriesUrl = '$baseUrl/wp-json/wc/v3/products/categories';

  // Web view URLs for cart and checkout
  static const String cartUrl = '$baseUrl/cart';
  static const String checkoutUrl = '$baseUrl/checkout';
}