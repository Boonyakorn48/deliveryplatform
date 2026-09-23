import 'order_status.dart';

class Courier {
  const Courier({
    required this.name,
    required this.vehicleType,
    required this.plateNumber,
    this.phone,
  });

  final String name;
  final String vehicleType;
  final String plateNumber;
  final String? phone;

  factory Courier.fromJson(Map<String, dynamic> json) {
    return Courier(
      name: json['name'] as String? ?? '',
      vehicleType: json['vehicle_type'] as String? ?? '',
      plateNumber: json['plate_number'] as String? ?? '',
      phone: json['phone'] as String?,
    );
  }
}

class TrackedOrder {
  const TrackedOrder({
    required this.id,
    required this.restaurantName,
    required this.itemCount,
    required this.total,
    required this.status,
    required this.dropoffLat,
    required this.dropoffLng,
    this.etaMinutes,
    this.courier,
    this.courierLat,
    this.courierLng,
  });

  final String id;
  final String restaurantName;
  final int itemCount;
  final double total;
  final OrderStatus status;
  final int? etaMinutes;
  final Courier? courier;
  final double? courierLat;
  final double? courierLng;
  final double dropoffLat;
  final double dropoffLng;

  factory TrackedOrder.fromJson(Map<String, dynamic> json) {
    return TrackedOrder(
      id: json['id'].toString(),
      restaurantName: json['restaurant_name'] as String? ?? 'พัสดุ',
      itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      status: OrderStatusJson.fromWireValue(json['status'] as String? ?? 'PENDING'),
      etaMinutes: (json['eta_minutes'] as num?)?.toInt(),
      courier: json['courier'] != null ? Courier.fromJson(json['courier'] as Map<String, dynamic>) : null,
      courierLat: (json['courier_lat'] as num?)?.toDouble(),
      courierLng: (json['courier_lng'] as num?)?.toDouble(),
      dropoffLat: (json['dropoff_lat'] as num?)?.toDouble() ?? 0,
      dropoffLng: (json['dropoff_lng'] as num?)?.toDouble() ?? 0,
    );
  }
}
