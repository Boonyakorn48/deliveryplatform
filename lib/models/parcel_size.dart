enum ParcelSize { s, m, l }

extension ParcelSizeX on ParcelSize {
  String get label => switch (this) {
        ParcelSize.s => 'S · 5kg',
        ParcelSize.m => 'M · 15kg',
        ParcelSize.l => 'L · 30kg',
      };

  double get maxWeightKg => switch (this) {
        ParcelSize.s => 5,
        ParcelSize.m => 15,
        ParcelSize.l => 30,
      };

  /// ตัวคูณราคาเทียบกับขนาด S — ปรับให้ตรงสูตรจริงของ backend ภายหลัง
  double get priceMultiplier => switch (this) {
        ParcelSize.s => 1.0,
        ParcelSize.m => 1.4,
        ParcelSize.l => 1.9,
      };

  String get wireValue => name.toUpperCase();
}
