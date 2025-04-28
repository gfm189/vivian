// File: lib/utils/service_provider.dart
import '../services/woocommerce_service.dart';
import 'constants.dart';

// This function returns a properly initialized WooCommerceService
WooCommerceService getWooCommerceService() {
  return WooCommerceService(
    baseUrl: ApiConstants.baseUrl,
    consumerKey: ApiConstants.consumerKey,
    consumerSecret: ApiConstants.consumerSecret,
  );
}