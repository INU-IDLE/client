class ApiStation {
  final String stationName;
  final double latitude;
  final double longitude;

  ApiStation({
    required this.stationName,
    required this.latitude,
    required this.longitude,
  });

  factory ApiStation.fromJson(Map<String, dynamic> json) {
    return ApiStation(
      stationName: json['stationName'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
    );
  }
}
