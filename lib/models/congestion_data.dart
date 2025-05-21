class CongestionData {
  final String trainNo;
  final Map<String, dynamic> cars;

  CongestionData({
    required this.trainNo,
    required this.cars,
  });

  factory CongestionData.fromJson(Map<String, dynamic> json) {
    return CongestionData(
      trainNo: json['trainY'] as String,
      cars: json['cars'] as Map<String, dynamic>,
    );
  }
}
