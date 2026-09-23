import 'menu_item.dart';

class CartItem {
  CartItem({required this.menuItem, this.quantity = 1});

  final MenuItem menuItem;
  int quantity;

  double get subtotal => menuItem.price * quantity;
}
