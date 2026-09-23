/// TODO(location): เชื่อมต่อ package `geolocator` เพื่อขอสิทธิ์ตำแหน่งจริงตามสเปค
/// (01-CUSTOMER-APP.md § 1.2: "ขอสิทธิ์ตำแหน่งครั้งแรกที่เข้าหน้านี้ —
/// ถ้าปฏิเสธ ให้กรอกที่อยู่เองแล้ว geocode"). จนกว่าจะเชื่อม จะใช้พิกัด
/// ค่าเริ่มต้น (กรุงเทพฯ) แทนเพื่อให้ `GET /restaurants?lat&lng` และ
/// `GET /weather?lat&lng` เรียกได้ตั้งแต่ตอนนี้.
class LocationService {
  const LocationService();

  static const defaultLat = 13.7563;
  static const defaultLng = 100.5018;

  Future<({double lat, double lng})> currentOrDefault() async {
    return (lat: defaultLat, lng: defaultLng);
  }
}
