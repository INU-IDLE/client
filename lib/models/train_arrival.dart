class TrainArrival {
  final String trainNo;
  final String direction;
  final String arrivalTime; // "2분 30초 후" 형식
  final String status;
  final String destination;
  final String currentPosition;

  TrainArrival({
    required this.trainNo,
    required this.direction,
    required this.arrivalTime,
    required this.status,
    required this.destination,
    required this.currentPosition,
  });

  factory TrainArrival.fromJson(Map<String, dynamic> json) {
    return TrainArrival(
      trainNo: json['trainNo'],
      direction: json['direction'],
      arrivalTime: json['arrivalTime'],
      status: json['status'],
      destination: json['destination'],
      currentPosition: json['trainPosition'],
    );
  }

  // 도착 시간을 초 단위로 변환 (예: "2분 30초 후" → 150초)
  int get arrivalInSeconds {
    if (arrivalTime.contains('전역')) return 0; // "전역 진입"은 0초 처리
    final RegExp regex = RegExp(r'(\d+)분\s*(\d+)?초');
    final match = regex.firstMatch(arrivalTime);
    if (match == null) return 9999; // 오류 시 큰 값 반환
    final minutes = int.parse(match.group(1)!);
    final seconds = match.group(2) != null ? int.parse(match.group(2)!) : 0;
    return minutes * 60 + seconds;
  }
}
