// lib/screens/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';
import '../providers/cart_provider.dart';
import '../services/woocommerce_service.dart';
import '../providers/auth_provider.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _taxNumberController = TextEditingController();

  // Create a NumberFormat instance for consistent currency formatting
  final currencyFormatter = NumberFormat('#,##0.00', 'en_US');

  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  List<String> _availableTimeSlots = [];
  bool _isLoading = false;
  String _paymentMethod = 'cod'; // Default to Cash on Delivery
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;

  final WooCommerceService _wooService = WooCommerceService(
    baseUrl: 'https://vivianwater.com',
    consumerKey: 'ck_ef37137a3182237d24fc9b453cc47f29b6de49bf',
    consumerSecret: 'cs_40f7f340b14b3daec3668383ce80c86847dbca98',
  );

  @override
  void initState() {
    super.initState();

    // Pre-fill form with user data after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.isLoggedIn && authProvider.currentUser != null) {
        final user = authProvider.currentUser!;

        setState(() {
          if (user.name != null && user.name!.isNotEmpty) {
            _nameController.text = user.name!;
          }

          if (user.email != null && user.email!.isNotEmpty) {
            _emailController.text = user.email!;
          }

          _phoneController.text = user.phoneNumber;
        });
      }

      // Try to get user's initial location
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _taxNumberController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      loc.Location location = loc.Location();

      // First check if service is enabled
      bool serviceEnabled;
      try {
        serviceEnabled = await location.serviceEnabled();
      } catch (e) {
        print('Error checking if location service is enabled: $e');
        return;
      }

      if (!serviceEnabled) {
        try {
          serviceEnabled = await location.requestService();
        } catch (e) {
          print('Error requesting location service: $e');
          return;
        }

        if (!serviceEnabled) {
          return;
        }
      }

      // Then check for permission
      loc.PermissionStatus permissionStatus;
      try {
        permissionStatus = await location.hasPermission();
      } catch (e) {
        print('Error checking location permission: $e');
        return;
      }

      if (permissionStatus == loc.PermissionStatus.denied) {
        try {
          permissionStatus = await location.requestPermission();
        } catch (e) {
          print('Error requesting location permission: $e');
          return;
        }

        if (permissionStatus != loc.PermissionStatus.granted) {
          return;
        }
      }

      // Finally try to get location
      loc.LocationData? locationData;
      try {
        locationData = await location.getLocation();
      } catch (e) {
        print('Error getting location: $e');
        return;
      }

      if (locationData.latitude != null && locationData.longitude != null) {
        setState(() {
          _selectedLocation = LatLng(locationData!.latitude!, locationData.longitude!);
        });

        // Get address from location
        _getAddressFromLatLng(_selectedLocation!);
      }
    } catch (e) {
      print('Unexpected error in _getCurrentLocation: $e');
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address =
            '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}';

        // Clean up address (remove unnecessary commas)
        address = address.replaceAll(RegExp(r', ,'), ',');
        address = address.replaceAll(RegExp(r',,'), ',');
        address = address.replaceAll(RegExp(r'^,|,$'), '');

        setState(() {
          _addressController.text = address;
        });
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now().add(Duration(days: 1)),
      lastDate: DateTime.now().add(Duration(days: 30)),
      selectableDayPredicate: (DateTime day) {
        // Disable Fridays (Friday is day 5, where Monday is day 1)
        return day.weekday != 5;
      },
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.green,
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.green,
              surface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
              ),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null;
        _loadTimeSlots(picked);
      });
    }
  }

  Future<void> _loadTimeSlots(DateTime date) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final slots = await _wooService.getDeliveryTimeSlots(formattedDate);

      setState(() {
        _availableTimeSlots = slots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _availableTimeSlots = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load time slots: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a delivery date')),
      );
      return;
    }

    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a delivery time slot')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      final lineItems = cartProvider.items.map((item) => LineItem(
        productId: item.product.id,
        quantity: item.quantity,
      )).toList();

      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);

      final order = await _wooService.createOrder(
        customerName: _nameController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        deliveryDate: formattedDate,
        deliveryTime: _selectedTimeSlot!,
        lineItems: lineItems,
        paymentMethod: _paymentMethod,
      );

      // Clear cart after successful order
      cartProvider.clear();

      // Navigate to success screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderSuccessScreen(order: order),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper method to format prices consistently
  String formatPrice(double price) {
    return '${currencyFormatter.format(price)} SAR';
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User information card
                if (authProvider.isLoggedIn && authProvider.currentUser != null)
                  Card(
                    margin: EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Phone: ${authProvider.currentUser!.phoneNumber}',
                            style: TextStyle(fontSize: 16),
                          ),
                          if (authProvider.currentUser!.name != null)
                            Text(
                              'Name: ${authProvider.currentUser!.name}',
                              style: TextStyle(fontSize: 16),
                            ),
                          if (authProvider.currentUser!.email != null)
                            Text(
                              'Email: ${authProvider.currentUser!.email}',
                              style: TextStyle(fontSize: 16),
                            ),
                        ],
                      ),
                    ),
                  ),

                Text(
                  'Invoice details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                SizedBox(height: 16),

                // Full Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Full Address
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Full address *',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Google Maps
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _selectedLocation ?? LatLng(24.7136, 46.6753), // Default to Riyadh
                        zoom: 14.0,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                      },
                      onTap: (LatLng position) {
                        setState(() {
                          _selectedLocation = position;
                        });
                        _getAddressFromLatLng(position);
                      },
                      markers: _selectedLocation != null ? {
                        Marker(
                          markerId: MarkerId('selected_location'),
                          position: _selectedLocation!,
                          infoWindow: InfoWindow(title: 'Delivery Location'),
                        )
                      } : {},
                    ),
                  ),
                ),

                SizedBox(height: 8),

                // Use current location button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.my_location, size: 16),
                    label: Text('Use Current Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _getCurrentLocation,
                  ),
                ),

                SizedBox(height: 16),

                // Mobile Number
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Mobile number *',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    prefixText: '+',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your mobile number';
                    }
                    return null;
                  },
                  readOnly: true, // Make phone field read-only as it's already verified
                ),
                SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Tax Number (optional)
                TextFormField(
                  controller: _taxNumberController,
                  decoration: InputDecoration(
                    labelText: 'Customer Tax Number (optional)',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 24),

                // Delivery Date
                Text(
                  'Delivery date *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate != null
                              ? DateFormat('EEEE, MMMM d, y').format(_selectedDate!)
                              : 'Select a delivery date',
                          style: TextStyle(
                            color: _selectedDate != null ? Colors.black : Colors.grey[600],
                          ),
                        ),
                        Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Delivery Time
                if (_selectedDate != null) ...[
                  Text(
                    'Delivery time *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    width: double.infinity,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: Text('Select a time slot'),
                        value: _selectedTimeSlot,
                        items: _availableTimeSlots.map((timeSlot) {
                          return DropdownMenuItem<String>(
                            value: timeSlot,
                            child: Text(timeSlot),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTimeSlot = value;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                ],

                // Order Summary
                Text(
                  'Your request',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                SizedBox(height: 16),

                // Order items
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Product',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Total',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        color: Colors.white,
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: cartProvider.items.length,
                          itemBuilder: (ctx, i) {
                            final item = cartProvider.items[i];
                            // Parse and format the price properly
                            final priceWithVat = double.tryParse(item.product.price) ?? 0.0;
                            final totalPrice = priceWithVat * item.quantity;

                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${item.quantity}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      '${item.product.name}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    formatPrice(totalPrice),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // Order total
                      Container(
                        padding: EdgeInsets.all(16),
                        color: Colors.grey[200],
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Subtotal',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  formatPrice(cartProvider.totalAmount),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Final Total (incl. VAT)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  formatPrice(cartProvider.totalAmount),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'All prices include 15% VAT',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Payment Method
                Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),

                // Cash on delivery option
                RadioListTile<String>(
                  title: Text('Cash on delivery'),
                  value: 'cod',
                  groupValue: _paymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _paymentMethod = value!;
                    });
                  },
                  activeColor: Colors.blue,
                ),

                // Electronic payments option
                RadioListTile<String>(
                  title: Text('Electronic payments'),
                  value: 'electronic',
                  groupValue: _paymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _paymentMethod = value!;
                    });
                  },
                  activeColor: Colors.blue,
                ),

                SizedBox(height: 24),

                // Place Order Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _placeOrder,
                    child: Text(
                      'Confirm order',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}