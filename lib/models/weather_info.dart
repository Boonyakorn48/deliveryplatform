class WeatherInfo {
  const WeatherInfo({
    required this.temperatureC,
    required this.description,
    this.delayMinutesMin,
    this.delayMinutesMax,
  });

  final double temperatureC;
  final String description;
  final int? delayMinutesMin;
  final int? delayMinutesMax;

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    return WeatherInfo(
      temperatureC: (json['temperature_c'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String? ?? '',
      delayMinutesMin: (json['delay_minutes_min'] as num?)?.toInt(),
      delayMinutesMax: (json['delay_minutes_max'] as num?)?.toInt(),
    );
  }
}
