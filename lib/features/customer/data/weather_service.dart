import '../../../core/network/api_client.dart';
import '../../../models/weather_info.dart';

class WeatherService {
  WeatherService({this.token});
  final String? token;

  /// คืนค่า null เมื่อเรียก API ไม่สำเร็จ — หน้าแรกจะซ่อนแถบสภาพอากาศ
  /// โดยไม่ต้องแสดง error ตามสเปค (1.2 ข้อ 2).
  Future<WeatherInfo?> current({required double lat, required double lng}) async {
    try {
      final response = await ApiClient(token: token).get('/weather?lat=$lat&lng=$lng');
      return WeatherInfo.fromJson(response['data'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
