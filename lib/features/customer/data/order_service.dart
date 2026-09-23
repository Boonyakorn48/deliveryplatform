import '../../../core/network/api_client.dart';
import '../../../models/order_tracking.dart';

class OrderService {
  OrderService({this.token});
  final String? token;

  /// POST /orders — type=FOOD (สเปค 1.4)
  Future<String> createFoodOrder({
    required String restaurantId,
    required List<Map<String, dynamic>> items,
    required String dropoffAddress,
    required double dropoffLat,
    required double dropoffLng,
    String? note,
  }) async {
    final response = await ApiClient(token: token).post('/orders', {
      'type': 'FOOD',
      'restaurant_id': restaurantId,
      'items': items,
      'dropoff_address': dropoffAddress,
      'dropoff_lat': dropoffLat,
      'dropoff_lng': dropoffLng,
      'note': note,
    });
    final data = response['data'] as Map<String, dynamic>;
    return data['id'].toString();
  }

  /// POST /orders — type=PARCEL (สเปค 1.2 โหมดส่งพัสดุ)
  Future<String> createParcelOrder({
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required String dropoffAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String size,
  }) async {
    final response = await ApiClient(token: token).post('/orders', {
      'type': 'PARCEL',
      'pickup_address': pickupAddress,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'dropoff_address': dropoffAddress,
      'dropoff_lat': dropoffLat,
      'dropoff_lng': dropoffLng,
      'size': size,
    });
    final data = response['data'] as Map<String, dynamic>;
    return data['id'].toString();
  }

  Future<TrackedOrder> get(String orderId) async {
    final response = await ApiClient(token: token).get('/orders/$orderId');
    return TrackedOrder.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> rate(String orderId, {required int stars, String? comment}) async {
    await ApiClient(token: token).post('/orders/$orderId/rating', {
      'stars': stars,
      'comment': comment,
    });
  }
}
