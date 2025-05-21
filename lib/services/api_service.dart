import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rushcutter/models/train_arrival.dart';
Future<List<Map<String, dynamic>>> fetchRealTimeCongestionCarsList({
  required String lineCode,
  required String stationName,
  required String direction,
}) async {
  final arrivalsRes = await http.get(
    Uri.parse('http://43.200.50.230/api/v1/lines/$lineCode/trains/$stationName/arrivals'),
    headers: {'accept': '*/*'},
  );
  if (arrivalsRes.statusCode != 200) return [];
  final arrivalsData = jsonDecode(utf8.decode(arrivalsRes.bodyBytes));
  final arrivals = arrivalsData['arrivals'] as List;
  final trains = arrivals
      .where((e) => e['direction'] == direction)
      .take(2)
      .toList();

  return Future.wait(trains.map((e) async {
    final trainNo = e['trainNo'];
    final congestionRes = await http.get(
      Uri.parse('http://43.200.50.230/api/v1/congestion/real-time/$lineCode/$trainNo'),
      headers: {'accept': '*/*'},
    );
    if (congestionRes.statusCode == 200) {
      final congestionData = jsonDecode(utf8.decode(congestionRes.bodyBytes));
      return Map<String, dynamic>.from(congestionData['result']['cars']);
    }
    return <String, dynamic>{};
  }));
}
