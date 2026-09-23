/// Mirrors the `orders` table status column (see Database Design doc, section 4).
enum OrderStatus {
  pending,
  waitingForDelivery,
  accepted,
  pickingUp,
  onTheWay,
  delivered,
}

extension OrderStatusJson on OrderStatus {
  static const _wireValues = {
    OrderStatus.pending: 'PENDING',
    OrderStatus.waitingForDelivery: 'WAITING_FOR_DELIVERY',
    OrderStatus.accepted: 'ACCEPTED',
    OrderStatus.pickingUp: 'PICKING_UP',
    OrderStatus.onTheWay: 'ON_THE_WAY',
    OrderStatus.delivered: 'DELIVERED',
  };

  String get wireValue => _wireValues[this]!;

  static OrderStatus fromWireValue(String value) {
    return _wireValues.entries
        .firstWhere((entry) => entry.value == value, orElse: () => const MapEntry(OrderStatus.pending, ''))
        .key;
  }
}
