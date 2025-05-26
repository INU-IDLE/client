import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:rushcutter/models/station_api.dart';

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
        .replaceAll(RegExp(r'역$'), '')
        .replaceAll(RegExp(r'승차$'), '')
        .replaceAllMapped(RegExp(r'\(.*?\)'), (match) {
      return name == '신촌(경의중앙선)' ? match.group(0)! : '';
    })
        .trim();

    final match = stations.firstWhere(
          (station) => station['station_nm'] == cleaned,
      orElse: () => null,
    );

    print('🔍 정제 후 역 이름: $cleaned');
    return match?['fr_code'];
  }

}