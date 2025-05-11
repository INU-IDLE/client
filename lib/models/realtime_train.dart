// models/realtime_train.dart
class RealTimeTrain {
  final String trainId;
  final String currentStation;
  final String lastUpdated;

  RealTimeTrain({
    required this.trainId,
    required this.currentStation,
    required this.lastUpdated,
  });

  factory RealTimeTrain.fromJson(Map<String, dynamic> json) {
    return RealTimeTrain(
      trainId: json['trainNo']?.toString() ?? '',
      currentStation: json['statnNm']?.toString() ?? '',
      lastUpdated: json['recptnDt']?.toString() ?? '',
    );
  }
}
