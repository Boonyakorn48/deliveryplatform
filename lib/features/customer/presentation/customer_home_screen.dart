import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/parcel_size.dart';
import '../../../models/restaurant.dart';
import '../../../models/weather_info.dart';
import '../../../theme/app_theme.dart';
import '../../auth/data/auth_state.dart';
import '../data/cart_state.dart';
import '../data/location_service.dart';
import '../data/order_service.dart';
import '../data/restaurant_service.dart';
import '../data/weather_service.dart';
import 'cart_screen.dart';
import 'order_tracking_screen.dart';
import 'restaurant_menu_screen.dart';

enum _HomeMode { food, parcel }

/// 1.2 หน้าแรก (01-CUSTOMER-APP.md)
class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  static const _location = LocationService();

  _HomeMode _mode = _HomeMode.food;
  int _navIndex = 0;

  double? _lat;
  double? _lng;
  String _address = '89/12 ถ.พหลโยธิน แขวงจอมพล';

  WeatherInfo? _weather;
  bool _weatherFailed = false;

  Future<List<Restaurant>>? _restaurantsFuture;

  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  ParcelSize _parcelSize = ParcelSize.m;
  bool _creatingParcelOrder = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final position = await _location.currentOrDefault();
    if (!mounted) return;
    setState(() {
      _lat = position.lat;
      _lng = position.lng;
      _restaurantsFuture = _loadRestaurants();
    });
    _loadWeather();
  }

  Future<List<Restaurant>> _loadRestaurants() {
    final token = context.read<AuthState>().token;
    return RestaurantService(token: token).nearby(lat: _lat!, lng: _lng!);
  }

  Future<void> _loadWeather() async {
    final token = context.read<AuthState>().token;
    final result = await WeatherService(token: token).current(lat: _lat!, lng: _lng!);
    if (!mounted) return;
    setState(() {
      _weather = result;
      _weatherFailed = result == null;
    });
  }

  Future<void> _editAddress() async {
    final controller = TextEditingController(text: _address);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg), bottom: Radius.circular(AppRadius.lg)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('เปลี่ยนที่อยู่จัดส่ง', style: AppTextStyles.h1),
              const SizedBox(height: 14),
              TextField(controller: controller, decoration: const InputDecoration(labelText: 'ที่อยู่')),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                child: const Text('บันทึก'),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      setState(() => _address = result);
    }
  }

  void _openRestaurant(Restaurant restaurant) {
    final cart = context.read<CartState>();
    if (cart.wouldConflict(restaurant)) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: const Text('ล้างตะกร้า?'),
          content: const Text('ล้างตะกร้าเพื่อสั่งจากร้านใหม่?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('ยกเลิก')),
            FilledButton(
              onPressed: () {
                cart.clear();
                Navigator.of(context).pop();
                _pushRestaurant(restaurant);
              },
              child: const Text('ล้างตะกร้า'),
            ),
          ],
        ),
      );
    } else {
      _pushRestaurant(restaurant);
    }
  }

  void _pushRestaurant(Restaurant restaurant) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => RestaurantMenuScreen(restaurant: restaurant)));
  }

  double get _parcelEstimate {
    if (_pickupController.text.trim().isEmpty || _dropoffController.text.trim().isEmpty) return 0;
    // TODO(geocoding): แทนที่ระยะทางสมมตินี้ด้วยผลจาก Google Maps Distance Matrix
    // เมื่อเชื่อม geocoding จริงสำหรับต้นทาง/ปลายทางที่ผู้ใช้พิมพ์
    const assumedDistanceKm = 4.5;
    return (25 + assumedDistanceKm * 8) * _parcelSize.priceMultiplier;
  }

  Future<void> _createParcelOrder() async {
    if (_pickupController.text.trim().isEmpty || _dropoffController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรอกต้นทางและปลายทางก่อน')));
      return;
    }
    setState(() => _creatingParcelOrder = true);
    try {
      final token = context.read<AuthState>().token;
      final orderId = await OrderService(token: token).createParcelOrder(
        pickupAddress: _pickupController.text.trim(),
        pickupLat: _lat ?? LocationService.defaultLat,
        pickupLng: _lng ?? LocationService.defaultLng,
        dropoffAddress: _dropoffController.text.trim(),
        dropoffLat: _lat ?? LocationService.defaultLat,
        dropoffLng: _lng ?? LocationService.defaultLng,
        size: _parcelSize.wireValue,
      );
      if (!mounted) return;
      context.read<CartState>().setLastOrder(orderId);
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderId)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('สร้างงานจัดส่งไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _creatingParcelOrder = false);
    }
  }

  IconData get _weatherIcon {
    final text = _weather?.description ?? '';
    if (text.contains('ฝน')) return Icons.umbrella_rounded;
    if (text.contains('เมฆ') || text.contains('มืดครึ้ม')) return Icons.cloud_rounded;
    return Icons.wb_sunny_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final cart = context.watch<CartState>();
    final name = auth.userName ?? 'ลูกค้า';
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFFF06246)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.28), blurRadius: 14, offset: const Offset(0, 6))],
                    ),
                    child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('สวัสดี, $name', style: AppTextStyles.h1),
                        InkWell(
                          onTap: _editAddress,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textFaint),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(_address,
                                      maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption),
                                ),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textFaint),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // สภาพอากาศ — การ์ดเล็ก ๆ อ่านง่าย ไม่มีป้ายเทคนิค
            if (!_weatherFailed)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: AppShadows.soft,
                  ),
                  child: _weather == null
                      ? const SizedBox(
                          height: 20,
                          child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                        )
                      : Row(
                          children: [
                            Icon(_weatherIcon, color: AppColors.amber, size: 22),
                            const SizedBox(width: 10),
                            Text('${_weather!.temperatureC.round()}°', style: AppTextStyles.h1),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_weather!.description, style: AppTextStyles.caption)),
                          ],
                        ),
                ),
              ),

            // แท็บโหมด — pill switcher
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Row(
                  children: [
                    Expanded(
                      child: _ModeTab(label: 'สั่งอาหาร', selected: _mode == _HomeMode.food, onTap: () => setState(() => _mode = _HomeMode.food)),
                    ),
                    Expanded(
                      child: _ModeTab(label: 'ส่งพัสดุ', selected: _mode == _HomeMode.parcel, onTap: () => setState(() => _mode = _HomeMode.parcel)),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(child: _mode == _HomeMode.food ? _buildFoodMode() : _buildParcelMode()),

            _BottomNav(cartCount: cart.itemCount, index: _navIndex, onTap: (i) => setState(() => _navIndex = i)),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
          child: Text('ร้านใกล้คุณ', style: AppTextStyles.h1),
        ),
        Expanded(
          child: FutureBuilder<List<Restaurant>>(
            future: _restaurantsFuture,
            builder: (context, snapshot) {
              if (_restaurantsFuture == null || snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _ErrorState(
                  message: 'โหลดรายชื่อร้านไม่สำเร็จ',
                  onRetry: () => setState(() => _restaurantsFuture = _loadRestaurants()),
                );
              }
              final restaurants = snapshot.data ?? [];
              if (restaurants.isEmpty) {
                return const Center(child: Text('ยังไม่มีร้านใกล้คุณตอนนี้', style: AppTextStyles.caption));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: restaurants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _RestaurantCard(
                  restaurant: restaurants[index],
                  onTap: () => _openRestaurant(restaurants[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildParcelMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _pickupController,
                  decoration: const InputDecoration(labelText: 'ต้นทาง', prefixIcon: Icon(Icons.trip_origin, size: 18)),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _dropoffController,
                  decoration: const InputDecoration(labelText: 'ปลายทาง', prefixIcon: Icon(Icons.location_on_rounded, size: 18)),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 18),
                const Text('ขนาดพัสดุ', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 10),
                SegmentedButton<ParcelSize>(
                  segments: ParcelSize.values.map((s) => ButtonSegment(value: s, label: Text(s.label))).toList(),
                  selected: {_parcelSize},
                  onSelectionChanged: (selection) => setState(() => _parcelSize = selection.first),
                  showSelectedIcon: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ค่าส่งประมาณ', style: AppTextStyles.bodyMedium),
                Text('฿${_parcelEstimate.toStringAsFixed(0)}', style: AppTextStyles.display),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _creatingParcelOrder ? null : _createParcelOrder,
            child: _creatingParcelOrder
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('สร้างงานจัดส่ง'),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({required this.restaurant, required this.onTap});

  final Restaurant restaurant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.surfaceMuted, AppColors.border],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.restaurant_rounded, color: AppColors.textFaint, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(restaurant.name, style: AppTextStyles.h2, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(restaurant.cuisine, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 15, color: AppColors.amber),
                        const SizedBox(width: 2),
                        Text('${restaurant.rating}', style: AppTextStyles.captionMedium),
                        const SizedBox(width: 10),
                        Text('${restaurant.distanceKm} กม.', style: AppTextStyles.caption),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.pill)),
                          child: Text('${restaurant.etaMinutes} นาที',
                              style: AppTextStyles.captionMedium.copyWith(color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.cartCount, required this.index, required this.onTap});

  final int cartCount;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, 'หน้าแรก'),
      (Icons.shopping_bag_rounded, 'ตะกร้า'),
      (Icons.local_shipping_rounded, 'ติดตาม'),
      (Icons.person_rounded, 'โปรไฟล์'),
    ];
    return Container(
      padding: EdgeInsets.only(top: 10, bottom: MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final selected = i == index;
          final (icon, label) = items[i];
          return Expanded(
            child: InkWell(
              onTap: () => _handleTap(context, i),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(icon, size: 24, color: selected ? AppColors.primary : AppColors.textFaint),
                      if (i == 1 && cartCount > 0)
                        Positioned(
                          right: -6,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.pill)),
                            child: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? AppColors.primary : AppColors.textFaint)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  void _handleTap(BuildContext context, int i) {
    onTap(i);
    switch (i) {
      case 1:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen()));
        break;
      case 2:
        final lastOrderId = context.read<CartState>().lastOrderId;
        if (lastOrderId != null) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: lastOrderId)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ยังไม่มีออเดอร์ที่กำลังติดตามอยู่')));
        }
        break;
      case 3:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('หน้าโปรไฟล์จะเปิดให้ใช้งานในเฟสถัดไป')));
        break;
    }
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: AppTextStyles.caption),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(minimumSize: const Size(140, 44)),
            child: const Text('ลองอีกครั้ง'),
          ),
        ],
      ),
    );
  }
}