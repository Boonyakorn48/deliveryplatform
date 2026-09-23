import '../../../core/network/api_client.dart';
import '../../../models/menu_item.dart';
import '../../../models/restaurant.dart';

class RestaurantService {
  RestaurantService({this.token});
  final String? token;

  Future<List<Restaurant>> nearby({required double lat, required double lng}) async {
    final response = await ApiClient(token: token).get('/restaurants?lat=$lat&lng=$lng');
    final list = response['data'] as List<dynamic>? ?? [];
    return list.map((e) => Restaurant.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Restaurant> detail(String id) async {
    final response = await ApiClient(token: token).get('/restaurants/$id');
    return Restaurant.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<MenuItem>> menu(String restaurantId) async {
    final response = await ApiClient(token: token).get('/restaurants/$restaurantId/menu');
    final list = response['data'] as List<dynamic>? ?? [];
    return list.map((e) => MenuItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}
