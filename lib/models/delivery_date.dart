// lib/models/delivery_date.dart

class DeliveryDate {
  final String date;
  final String formattedDate;
  final bool available;

  DeliveryDate({
    required this.date,
    required this.formattedDate,
    required this.available,
  });

  factory DeliveryDate.fromJson(Map<String, dynamic> json) {
    return DeliveryDate(
      date: json['date'] ?? '',
      formattedDate: json['formatted_date'] ?? '',
      available: json['available'] ?? false,
    );
  }

  // Check if two delivery dates have the same date value
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeliveryDate && other.date == date;
  }

  @override
  int get hashCode => date.hashCode;
}