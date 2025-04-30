import 'dart:convert';
import 'package:http/http.dart' as http;


class PathService {
  Future<Map<String, dynamic>?> getShortestPath(String startFrCode, String endFrCode) async {
    final url = Uri.parse('http://10.0.2.2:8080/api/v1/path/shortest?start=$startFrCode&end=$endFrCode');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        print('에러 코드: ${response.statusCode}');
        print('에러 메시지: ${response.body}');
        return null;
      }
    } catch (e) {
      print('예외 발생: $e');
      return null;
    }
  }
}
