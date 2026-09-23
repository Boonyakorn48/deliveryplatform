class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.distanceKm,
    required this.etaMinutes,
    this.photoUrl,
    this.isOpen = true,
    this.openUntil,
  });

  final String id;
  final String name;
  final String cuisine;
  final double rating;
  final double distanceKm;
  final int etaMinutes;
  final String? photoUrl;
  final bool isOpen;
  final String? openUntil;

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      cuisine: json['cuisine'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      etaMinutes: (json['eta_minutes'] as num?)?.toInt() ?? 0,
      photoUrl: json['photo_url'] as String?,
      isOpen: json['is_open'] as bool? ?? true,
      openUntil: json['open_until'] as String?,
    );
  }
}
