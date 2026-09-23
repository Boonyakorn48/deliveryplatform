import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/menu_item.dart';
import '../../../models/restaurant.dart';
import '../../../theme/app_theme.dart';
import '../../auth/data/auth_state.dart';
import '../data/cart_state.dart';
import '../data/restaurant_service.dart';
import 'cart_screen.dart';

/// 1.3 เมนูร้าน (01-CUSTOMER-APP.md)
class RestaurantMenuScreen extends StatefulWidget {
  const RestaurantMenuScreen({super.key, required this.restaurant});

  final Restaurant restaurant;

  @override
  State<RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> {
  late Future<List<MenuItem>> _menuFuture;

  @override
  void initState() {
    super.initState();
    context.read<CartState>().setRestaurant(widget.restaurant);
    _menuFuture = _loadMenu();
  }

  Future<List<MenuItem>> _loadMenu() {
    final token = context.read<AuthState>().token;
    return RestaurantService(token: token).menu(widget.restaurant.id);
  }

  void _onAdd(MenuItem item) {
    // TODO(options): ถ้าเมนูมีตัวเลือก (เผ็ด/ขนาด) ให้เปิด bottom sheet ก่อนเพิ่มลงตะกร้า
    context.read<CartState>().addItem(item);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        content: Text('เพิ่ม ${item.name} ลงตะกร้าแล้ว'),
        duration: const Duration(milliseconds: 1000),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.restaurant;
    final cart = context.watch<CartState>();

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  height: 210,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.surfaceMuted, AppColors.border],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(child: Icon(Icons.restaurant_rounded, size: 48, color: AppColors.textFaint)),
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -22),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 18),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: AppShadows.card,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(restaurant.name, style: AppTextStyles.h1),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: AppColors.amber),
                            const SizedBox(width: 2),
                            Text('${restaurant.rating}', style: AppTextStyles.captionMedium),
                            const SizedBox(width: 12),
                            Text('${restaurant.distanceKm} กม. · เปิดถึง ${restaurant.openUntil ?? '-'}', style: AppTextStyles.caption),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.pill)),
                              child: Text('${restaurant.etaMinutes} นาที', style: AppTextStyles.captionMedium.copyWith(color: AppColors.primary)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                sliver: SliverToBoxAdapter(child: Text('เมนู', style: AppTextStyles.h1)),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                sliver: FutureBuilder<List<MenuItem>>(
                  future: _menuFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(
                          child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())));
                    }
                    if (snapshot.hasError) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Text('โหลดเมนูไม่สำเร็จ', style: AppTextStyles.caption),
                              const SizedBox(height: 10),
                              OutlinedButton(
                                onPressed: () => setState(() => _menuFuture = _loadMenu()),
                                style: OutlinedButton.styleFrom(minimumSize: const Size(140, 44)),
                                child: const Text('ลองอีกครั้ง'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('ร้านนี้ยังไม่มีเมนู', style: AppTextStyles.caption)),
                        ),
                      );
                    }
                    return SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _MenuCard(item: items[i], onAdd: () => _onAdd(items[i])),
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: _RoundIconButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.of(context).pop()),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: cart.isEmpty
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen())),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ไปที่ตะกร้า · ${cart.itemCount} รายการ'),
                  Text('฿${cart.subtotal.toStringAsFixed(0)}'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: AppColors.shadow,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.item, required this.onAdd});

  final MenuItem item;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.soft),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppTextStyles.bodyMedium),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(item.description, style: AppTextStyles.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 6),
                Text('฿${item.price.toStringAsFixed(0)}', style: AppTextStyles.h2.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _RoundIconButton(icon: Icons.add_rounded, onTap: onAdd),
        ],
      ),
    );
  }
}