// services/realtime_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/realtime_train.dart';

class RealTimeService {
  final Dio _dio = Dio();
  final String _apiKey = dotenv.env['SUBWAY_API_KEY']!;

  Future<List<RealTimeTrain>> getRealTimePosition({
    required String lineNumber,
    required String direction,
  }) async {
    try {
      final response = await _dio.get(
        'http://openapi.seoul.go.kr:8088/$_apiKey/json/SearchRealTimePosition/1/100/$lineNumber',
        queryParameters: {
          'SERVICE_KEY': _apiKey,
          'UPDN_LINE': direction,
        },
      );

      return (response.data['SearchRealTimePosition']['row'] as List)
          .map((e) => RealTimeTrain.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('API 호출 실패: $e');
    }
  }
}
