import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:rushcutter/models/station.dart';

class StationService {
  Future<List<Station>> loadStationData(String jsonPath) async {
    String jsonString = await rootBundle.loadString(jsonPath);
    List<dynamic> jsonList = jsonDecode(jsonString);

    return jsonList.map((json) => Station(
      stationName: json['station_name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    )).toList();
  }
}
