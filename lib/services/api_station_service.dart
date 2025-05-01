import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:rushcutter/models/station_api.dart'; // ✅ ApiStation 클래스 경로

class ApiStationService {
  Future<List<ApiStation>> loadStationData(String jsonPath) async {
    String jsonString = await rootBundle.loadString(jsonPath);
    List<dynamic> jsonList = jsonDecode(jsonString);

    return jsonList.map((json) => ApiStation.fromJson(json)).toList();
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
