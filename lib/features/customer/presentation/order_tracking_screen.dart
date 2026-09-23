import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/order_status.dart';
import '../../../models/order_tracking.dart';
import '../../../theme/app_theme.dart';
import '../../auth/data/auth_state.dart';
import '../data/order_service.dart';

/// 1.5 ติดตามออเดอร์ (01-CUSTOMER-APP.md)
///
/// หมายเหตุ realtime: sync สถานะด้วยการ poll `GET /orders/{id}` ทุก 4 วิ
/// (ไม่ต้องเพิ่ม dependency ใหม่). ถ้าต้องการ WebSocket จริงตามสเปค
/// ("subscribe order:{id}", `location.updated`), ให้เพิ่ม package
/// `web_socket_channel` แล้วแทนที่ `_fetch` ด้วยการ listen `ApiConfig.wsUrl`.
class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  TrackedOrder? _order;
  String? _error;
  Timer? _timer;
  bool _ratingSubmitted = false;

  static const _steps = [
    (OrderStatus.pending, 'PENDING', 'สั่งอาหารเรียบร้อยแล้ว'),
    (OrderStatus.waitingForDelivery, 'WAITING_FOR_DELIVERY', 'รอคนส่งรับงาน'),
    (OrderStatus.accepted, 'ACCEPTED', 'คนส่งรับงานแล้ว'),
    (OrderStatus.pickingUp, 'PICKING_UP', 'กำลังไปรับอาหาร'),
    (OrderStatus.onTheWay, 'ON_THE_WAY', 'กำลังนำอาหารไปส่ง'),
    (OrderStatus.delivered, 'DELIVERED', 'ส่งสำเร็จ'),
  ];

  OrderService get _service => OrderService(token: context.read<AuthState>().token);

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _fetch(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch({bool silent = false}) async {
    try {
      final order = await _service.get(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _error = null;
      });
      if (order.status == OrderStatus.delivered) {
        _timer?.cancel();
      }
    } catch (e) {
      if (!mounted || silent) return;
      setState(() => _error = 'โหลดข้อมูลออเดอร์ไม่สำเร็จ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;

    return Scaffold(
      body: SafeArea(
        child: order == null
            ? Center(child: _error != null ? _RetryState(message: _error!, onRetry: _fetch) : const CircularProgressIndicator())
            : Column(
                children: [
                  _buildTopBar(order),
                  _buildMap(order),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('สถานะออเดอร์', style: AppTextStyles.h2),
                                if (order.status != OrderStatus.delivered && order.etaMinutes != null)
                                  Text('ถึงใน ~${order.etaMinutes} นาที',
                                      style: AppTextStyles.h2.copyWith(color: AppColors.primary)),
                                if (order.status == OrderStatus.delivered)
                                  const Text('ส่งแล้ว', style: AppTextStyles.h2),
                              ],
                            ),
                          ),
                          ..._buildTimeline(order),
                          if (order.courier != null && order.status.index >= OrderStatus.accepted.index)
                            _buildCourierCard(order.courier!),
                          if (order.status == OrderStatus.delivered && !_ratingSubmitted) _buildRating(order),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      child: const Text('กลับหน้าแรก'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTopBar(TrackedOrder order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 2))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ORD-${order.id}', style: AppTextStyles.h2),
                Text('${order.restaurantName} · ${order.itemCount} รายการ · ฿${order.total.toStringAsFixed(0)}',
                  style: AppTextStyles.caption),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(order.status.wireValue, style: AppTextStyles.captionMedium.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(TrackedOrder order) {
    final delivered = order.status == OrderStatus.delivered;
    if (delivered) return const SizedBox.shrink();
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.surfaceMuted, boxShadow: AppShadows.soft),
      child: Stack(
        children: [
          CustomPaint(size: Size.infinite, painter: _GridPainter()),
          if (order.courierLat != null)
            const Align(alignment: Alignment(-0.2, -0.1), child: _PulsingDot(color: AppColors.primary, size: 14)),
          const Align(alignment: Alignment(0.5, 0.3), child: Icon(Icons.crop_square, size: 16, color: AppColors.textPrimary)),
          const Positioned(left: 16, bottom: 12, child: Text('กำลังอัปเดตตำแหน่ง', style: AppTextStyles.caption)),
        ],
      ),
    );
  }

  List<Widget> _buildTimeline(TrackedOrder order) {
    final currentIndex = order.status.index;
    return List.generate(_steps.length, (i) {
      final (_, code, meaning) = _steps[i];
      final passed = i <= currentIndex;
      final isCurrent = i == currentIndex;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 1))),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(border: Border.all(color: AppColors.border)),
              child: Text('${i + 1}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
            ),
            const SizedBox(width: 10),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: passed ? AppColors.primary : Colors.transparent,
                border: passed ? null : Border.all(color: AppColors.border),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(code, style: AppTextStyles.captionMedium.copyWith(color: passed ? AppColors.textPrimary : AppColors.textSecondary)),
                  Text(meaning, style: AppTextStyles.caption),
                ],
              ),
            ),
            if (isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Text('ตอนนี้', style: AppTextStyles.captionMedium),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildCourierCard(Courier courier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border, width: 2))),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
            child: Text(courier.name.isNotEmpty ? courier.name.substring(0, 1).toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${courier.name} · คนส่ง', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                Text('${courier.vehicleType} · ${courier.plateNumber}', style: AppTextStyles.caption),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
            child: const Text('โทร'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
            child: const Text('แชท'),
          ),
        ],
      ),
    );
  }

  Widget _buildRating(TrackedOrder order) {
    int stars = 5;
    final commentController = TextEditingController();
    return StatefulBuilder(
      builder: (context, setLocalState) => Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ให้คะแนนคนส่ง', style: AppTextStyles.h1),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) {
                final filled = i < stars;
                return IconButton(
                  onPressed: () => setLocalState(() => stars = i + 1),
                  icon: Icon(filled ? Icons.star : Icons.star_border, color: AppColors.primary),
                );
              }),
            ),
            TextField(controller: commentController, decoration: const InputDecoration(labelText: 'ความเห็น (ถ้ามี)')),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                try {
                  await _service.rate(order.id, stars: stars, comment: commentController.text.trim());
                } catch (_) {
                  // เก็บ rating ไม่สำเร็จ — ไม่บล็อก UI ของผู้ใช้
                }
                if (mounted) setState(() => _ratingSubmitted = true);
              },
              child: const Text('ส่งคะแนน'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_controller),
      child: Container(width: widget.size, height: widget.size, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RetryState extends StatelessWidget {
  const _RetryState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, style: AppTextStyles.caption),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onRetry, style: OutlinedButton.styleFrom(minimumSize: const Size(120, 40)), child: const Text('ลองอีกครั้ง')),
      ],
    );
  }
}
