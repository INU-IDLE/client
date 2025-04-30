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

  Future<String?> getFrCodeByStationName(String stationName) async {
    final jsonString = await rootBundle.loadString('assets/station_info.json');
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

    for (final station in jsonMap['DATA']) {
      if (station['station_nm'] == stationName.replaceAll('역', '')) {
        return station['fr_code'];
      }
    }
    return null;
  }
}
