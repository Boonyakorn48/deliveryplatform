import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../auth/data/auth_state.dart';
import '../data/cart_state.dart';
import '../data/order_service.dart';
import 'order_tracking_screen.dart';

/// 1.4 ตะกร้า + สั่งซื้อ (01-CUSTOMER-APP.md)
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _addressController = TextEditingController(text: '89/12 ถ.พหลโยธิน แขวงจอมพล');
  final _noteController = TextEditingController();
  bool _placing = false;
  String? _error;

  @override
  void dispose() {
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _confirmRemove(BuildContext context, CartState cart, String menuItemId) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบรายการ?'),
        content: const Text('ต้องการลบรายการนี้ออกจากตะกร้าใช่หรือไม่'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('ยกเลิก')),
          FilledButton(
            onPressed: () {
              cart.removeItem(menuItemId);
              Navigator.of(context).pop();
            },
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder(CartState cart) async {
    if (cart.isEmpty || cart.restaurant == null) return;
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      setState(() => _error = 'กรุณาระบุที่อยู่จัดส่ง');
      return;
    }
    setState(() {
      _placing = true;
      _error = null;
    });
    try {
      final token = context.read<AuthState>().token;
      final orderId = await OrderService(token: token).createFoodOrder(
        restaurantId: cart.restaurant!.id,
        items: cart.items.map((item) => {'menu_item_id': item.menuItem.id, 'qty': item.quantity}).toList(),
        dropoffAddress: address,
        // TODO(geocoding): แทนพิกัดสมมตินี้ด้วยผลลัพธ์จากแผนที่ปักหมุดเต็มจอ (GOOGLE MAPS API · PIN LOCATION)
        dropoffLat: 13.7563,
        dropoffLng: 100.5018,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      cart.setLastOrder(orderId);
      cart.clear();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderId)));
    } catch (e) {
      setState(() => _error = 'สั่งซื้อไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: 'ย้อนกลับ',
                  ),
                  const SizedBox(width: 4),
                  const Text('ตะกร้า', style: AppTextStyles.h1),
                ],
              ),
            ),
            if (_error != null)
              Container(
                width: double.infinity,
                color: const Color(0xFFFCE7E5),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Text(_error!, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
              ),
            Expanded(
              child: cart.isEmpty
                  ? const Center(child: Text('ตะกร้าว่าง', style: AppTextStyles.caption))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            ...cart.items.map((item) => Container(
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                boxShadow: AppShadows.soft,
                              ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            Text(item.menuItem.name, style: AppTextStyles.bodyMedium),
                                          Text('฿${item.menuItem.price.toStringAsFixed(0)} × ${item.quantity}',
                                              style: AppTextStyles.caption),
                                        ],
                                      ),
                                    ),
                                    OutlinedButton(
                                      onPressed: () {
                                        if (cart.willRemoveOnDecrement(item.menuItem.id)) {
                                          _confirmRemove(context, cart, item.menuItem.id);
                                        } else {
                                          cart.decrement(item.menuItem.id);
                                        }
                                      },
                                      style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(44, 44),
                                          padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm))),
                                          child: const Icon(Icons.remove_rounded, size: 18),
                                    ),
                                    SizedBox(
                                        width: 22,
                                        child: Text('${item.quantity}',
                                            textAlign: TextAlign.center, style: AppTextStyles.h2)),
                                    OutlinedButton(
                                      onPressed: () => cart.increment(item.menuItem.id),
                                      style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(44, 44),
                                          padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm))),
                                          child: const Icon(Icons.add_rounded, size: 18),
                                    ),
                                    SizedBox(
                                      width: 52,
                                      child: Text('฿${item.subtotal.toStringAsFixed(0)}',
                                          textAlign: TextAlign.right, style: AppTextStyles.h2),
                                    ),
                                  ],
                                ),
                              )),
                          Container(
                            margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              boxShadow: AppShadows.soft,
                            ),
                            child: Column(
                              children: [
                                _SummaryRow(label: 'ราคารวมอาหาร', value: cart.subtotal),
                                _SummaryRow(
                                    label: 'ค่าจัดส่ง (${cart.deliveryDistanceKm.toStringAsFixed(1)} กม.)',
                                    value: cart.deliveryFee),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('รวมทั้งหมด', style: AppTextStyles.bodyMedium),
                                    Text('฿${cart.total.toStringAsFixed(0)}', style: AppTextStyles.display),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                    controller: _addressController,
                                    decoration: const InputDecoration(labelText: 'ที่อยู่จัดส่ง / Delivery address')),
                                const SizedBox(height: 12),
                                Container(
                                  height: 110,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                  ),
                                  child: Stack(
                                    children: [
                                      const Center(child: Icon(Icons.location_on, color: AppColors.primary)),
                                      const Positioned(
                                        left: 12,
                                        bottom: 10,
                                        child: Text('ตำแหน่งจัดส่ง', style: AppTextStyles.caption),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                    controller: _noteController,
                                    decoration: const InputDecoration(labelText: 'หมายเหตุถึงร้าน')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.surface,
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: (cart.isEmpty || _placing) ? null : () => _placeOrder(cart),
              child: _placing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ยืนยันคำสั่งซื้อ / Place order'),
                        Text('฿${cart.total.toStringAsFixed(0)}'),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Text('฿${value.toStringAsFixed(0)}', style: AppTextStyles.body),
        ],
      ),
    );
  }
}
