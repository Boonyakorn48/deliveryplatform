import 'package:flutter/foundation.dart';
import '../../../models/cart_item.dart';
import '../../../models/menu_item.dart';
import '../../../models/restaurant.dart';

/// App-wide cart, provided above [AppRouter] alongside [AuthState] so it
/// survives navigation between 1.2 → 1.3 → 1.4 and gets cleared once an
/// order is placed successfully.
class CartState extends ChangeNotifier {
  Restaurant? _restaurant;
  final Map<String, CartItem> _items = {};

  /// Remembers the most recently created order so the bottom-nav "ติดตาม"
  /// tab has somewhere to go without a full order-history feature (Phase 2).
  String? lastOrderId;

  Restaurant? get restaurant => _restaurant;
  List<CartItem> get items => _items.values.toList(growable: false);
  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.values.fold(0, (sum, item) => sum + item.subtotal);
  bool get isEmpty => _items.isEmpty;

  /// ระยะทางร้าน→ที่อยู่จัดส่ง (กม.) — ใช้ค่าประมาณจาก distance ตอนค้นหาร้านใกล้คุณ
  double get deliveryDistanceKm => _restaurant?.distanceKm ?? 0;

  /// สูตรคร่าว ๆ เพื่อแสดงผลในหน้า UI — แทนที่ด้วยค่าจริงจาก backend เมื่อพร้อม
  double get deliveryFee => 15 + deliveryDistanceKm * 8;

  double get total => subtotal + deliveryFee;

  /// true เมื่อกำลังสั่งจากร้านใหม่ทั้งที่ตะกร้ามีของจากร้านอื่นอยู่ (ต้อง confirm ล้างตะกร้าก่อน)
  bool wouldConflict(Restaurant next) =>
      _restaurant != null && _restaurant!.id != next.id && _items.isNotEmpty;

  void setRestaurant(Restaurant restaurant) {
    _restaurant = restaurant;
    notifyListeners();
  }

  void addItem(MenuItem menuItem) {
    final existing = _items[menuItem.id];
    if (existing != null) {
      existing.quantity += 1;
    } else {
      _items[menuItem.id] = CartItem(menuItem: menuItem);
    }
    notifyListeners();
  }

  void increment(String menuItemId) {
    _items[menuItemId]?.quantity += 1;
    notifyListeners();
  }

  /// true ถ้าการกด `-` รอบนี้จะทำให้รายการหมด (ควร confirm ก่อนลบ ตามสเปค 1.4)
  bool willRemoveOnDecrement(String menuItemId) => (_items[menuItemId]?.quantity ?? 0) <= 1;

  void decrement(String menuItemId) {
    final item = _items[menuItemId];
    if (item == null) return;
    if (item.quantity <= 1) {
      _items.remove(menuItemId);
    } else {
      item.quantity -= 1;
    }
    notifyListeners();
  }

  void removeItem(String menuItemId) {
    _items.remove(menuItemId);
    notifyListeners();
  }

  void setLastOrder(String orderId) {
    lastOrderId = orderId;
    notifyListeners();
  }

  void clear() {
    _restaurant = null;
    _items.clear();
    notifyListeners();
  }
}
