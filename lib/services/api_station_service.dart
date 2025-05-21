import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:rushcutter/models/station_api.dart'; // ✅ ApiStation 클래스 경로


class ApiStationService {
  Future<List<ApiStation>> loadStationData(String jsonPath) async {
    String jsonString = await rootBundle.loadString(jsonPath);
    List<dynamic> jsonList = jsonDecode(jsonString);

    return jsonList.map((json) => ApiStation.fromJson(json)).toList();
  }

  Future<String?> getFrCodeByStationName(String name) async {
    final data = await rootBundle.loadString('assets/station_info.json');
    final json = jsonDecode(data); // 이건 Map
    final stations = json['DATA'] as List; // 여기서 List만 뽑아내야 함


    String cleaned = name
        .replaceAll(RegExp(r'역$'), '')           // '역' 제거
        .replaceAll(RegExp(r'승차$'), '')         // '승차' 제거
        .replaceAll(RegExp(r'\(.*?\)'), '')       // 괄호 안 정보 제거
        .trim();

    final match = stations.firstWhere(
          (station) => station['station_nm'] == cleaned,
      orElse: () => null,
    );

    print('🔍 정제 후 역 이름: $cleaned');
    return match?['fr_code'];
  }

}
