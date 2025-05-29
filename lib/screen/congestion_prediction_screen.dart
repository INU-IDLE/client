import 'package:flutter/material.dart';
import 'real_time_bottom_sheet.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rushcutter/services/api_station_service.dart';
import 'package:rushcutter/data/line_mapping.dart';
import 'package:rushcutter/services/path_service.dart';


class CongestionPredictionScreen extends StatefulWidget {
  const CongestionPredictionScreen({Key? key}) : super(key: key);

  @override
  State<CongestionPredictionScreen> createState() => _CongestionPredictionScreenState();
}

// ✅ 상태 클래스 안에 넣기
class _CongestionPredictionScreenState extends State<CongestionPredictionScreen> {
  late String line;
  late String station;
  late String destination;
  late String fastTransfer;
  late String time;
  late String duration;
  late String stationCount;
  late IconData icon;
  late Color color;
  late bool isFavorite;
  late TimeOfDay departureTime;
  late TimeOfDay arrivalTime;
  late String actualArrival;
  late String originalStation;
  int transferCount = 0;
  int predictionOffsetMinutes = 10;
  bool _isInitialized = false;
  Map<String, Map<String, dynamic>> congestionData = {};
  Map<String, Map<String, dynamic>> congestionDataFuture = {};
  String selectedDayType = '평일';
  String? updnLine;
  String? lineName;
  String _getApiStationName(String station) {
    return _stationNameExceptions[station] ?? station;
  }
  static const Map<String, String> _stationNameExceptions = {
    // 1호선
    '쌍용': '쌍용(나사렛대)',
    // 4호선
    '총신대입구': '총신대입구(이수)', // 7호선
    // 5호선
    '신정': '신정(은행정)',
    '오목교': '오목교(목동운동장앞)',
    '군자': '군자(능동)', // 7호선
    '아차산': '아차산(어린이대공원후문)',
    '광나루': '광나루(장신대)',
    '천호': '천호(풍납토성)', // 8호선
    '굽은다리': '굽은다리(강동구민회관앞)',
    '올림픽공원': '올림픽공원(한국체대)',
    // 6호선
    '새절': '새절(신사)',
    '증산': '증산(명지대앞)',
    '월드컵경기장' : '월드컵경기장(성산)',
    '대흥': '대흥(서강대앞)',
    '안암': '안암(고대병원앞)',
    '월곡': '월곡(동덕여대)',
    '상월곡': '상월곡(한국과학기술연구원)',
    '화랑대': '화랑대(서울여대입구)',
    // 7호선
    '공릉': '공릉(서울산업대입구)',
    '어린이대공원': '어린이대공원(세종대)',
    '숭실대입구': '숭실대입구(살피재)',
    '상도': '상도(중앙대앞)',

    // 8호선
    '몽촌토성': '몽촌토성(평화의문)',
    '남한산성입구': '남한산성입구(성남법원,검찰청)',
  };
  Future<List<Map<String, String>>> printRealTimeTrainNos() async {
    String? direction = updnLine;
    String? apiDirection = direction;

    // 2호선은 direction을 '내선'/'외선'으로 변환
    if (line == '2호선') {
      if (direction == '상행') apiDirection = '내선';
      if (direction == '하행') apiDirection = '외선';
    }

    final lineName = getApiLineName(line) ?? line;
    if (lineName.isEmpty) {
      print('❌ 지원하지 않는 노선입니다: $line');
      return [];
    }

    final apiStation = _getApiStationName(station);
    print('➡️ 도착정보 API 요청: $lineName, 역: $apiStation');
    final arrivalsRes = await http.get(
      Uri.parse(
          'http://43.200.50.230/api/v1/lines/$lineName/trains/$apiStation/arrivals'),
      headers: {'accept': '*/*'},
    );
    if (arrivalsRes.statusCode != 200) {
      print('❌ 도착정보 API 호출 실패: ${arrivalsRes.statusCode}');
      print(
          '❌ URL: http://43.200.50.230/api/v1/lines/$lineName/trains/$station/arrivals');
      return [];
    }
    final arrivalsData = jsonDecode(utf8.decode(arrivalsRes.bodyBytes));
    final arrivals = arrivalsData['arrivals'] as List;

    if (apiDirection == null) {
      print('❌ 방향 정보가 없습니다. 경로를 먼저 검색하세요.');
      return [];
    }

    final trains = arrivals
        .where((e) => e['direction'] == apiDirection)
        .take(2)
        .toList();
    final trainInfoList = trains.map((e) => {
      'trainNo': e['trainNo'].toString(),
      'arrivalTime': e['arrivalTime'].toString(),
    }).toList();

    print('✅ $apiDirection 방향 열차 번호 1~2개: $trainInfoList');
    return trainInfoList;
  }

  Future<List<Map<String, dynamic>>> fetchRealTimeCongestionCarsList(trainNos) async {
    final lineCode = _getLineCodeByName(line); // 혼잡도 API는 숫자/코드!
    List<Map<String, dynamic>> carsList = [];

    for (final trainNo in trainNos) {
      final res = await http.get(
        Uri.parse('http://43.200.50.230/api/v1/congestion/real-time/$lineCode/$trainNo'),
        headers: {'accept': '*/*'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final cars = data['result']?['cars'];
        if (cars != null && cars is Map<String, dynamic>) {
          carsList.add(Map<String, dynamic>.from(cars));
        }
      }
    }
    return carsList;
  }

  @override
  void initState() {
    super.initState();
    final weekday = DateTime.now().weekday;
    if (weekday == DateTime.saturday) {
      selectedDayType = '토요일';
    } else if (weekday == DateTime.sunday) {
      selectedDayType = '일요일';
    } else {
      selectedDayType = '평일';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};

    line = args['line'];
    originalStation = args['station'] as String;
    station = originalStation
        .replaceAll(RegExp(r'\s*승차$'), '')
        .replaceAll(RegExp(r'\(.*?\)'), '')
        .trim();
    destination = args['destination'];
    fastTransfer = args['fastTransfer'];
    duration = args['duration'];
    stationCount = args['stationCount'];
    icon = IconData(args['iconCodePoint'], fontFamily: 'MaterialIcons');
    color = Color(args['colorValue']);
    isFavorite = args['isFavorite'] ?? false;
    time = args['time'] ?? '00:00';

    departureTime = _parseTimeOfDay(args['departureTime'] ?? '00:00');
    arrivalTime = _parseTimeOfDay(args['arrivalTime'] ?? '00:00');
    actualArrival = args['actualArrival'] ?? '도착역';

    _isInitialized = true;
    transferCount = args['transferCount'] ?? 0;
    fetchCongestionPrediction();
  }


  TimeOfDay _parseTimeOfDay(String timeStr) {
    final format = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(AM|PM)', caseSensitive: false);
    final match = format.firstMatch(timeStr.trim());

    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
      String period = match.group(3)!.toUpperCase();

      if (period == 'PM' && hour < 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    }

    // 기본값 처리 (24시간 포맷인 경우)
    if (timeStr.contains(':')) {
      final parts = timeStr.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    // 파싱 실패 시 fallback
    return const TimeOfDay(hour: 0, minute: 0);
  }

  Future<void> fetchCongestionPrediction() async {
    print('✅ fetchCongestionPrediction() 호출됨');
    print('🔍 line: $line');
    print('🔍 station: $station');
    print('➡️ dayType: $selectedDayType');
    print('🕒 [현재시간 요청] departureTime: ${departureTime.hour}:${departureTime.minute}');

    final lineCode = _getLineCodeByName(line);
    if (!(["2", "3", "4", "5", "6", "7", "8"].contains(lineCode))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 40, color: Colors.black),
                  const SizedBox(height: 16),
                  const Text(
                    '예측 혼잡도를 지원하지 않는 경로입니다.',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '지하철 2~8호선의 혼잡도만 제공됩니다.',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _showRealTimeModal(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4262C5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('실시간'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Future.delayed(const Duration(milliseconds: 100), () {
                              if (mounted) {
                                Navigator.of(context).maybePop();
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE0E0E0),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('확인'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      });
      return;
    }

    final stationService = ApiStationService();
    final startCode = (await stationService.getFrCodeByStationName(station))?.toString();
    final endCode = (await stationService.getFrCodeByStationName(destination))?.toString();

    if (startCode == null || endCode == null) {
      print('❌ 혼잡도 예측: stationCode를 찾을 수 없습니다.');
      return;
    }

    final pathService = PathService();
    final pathData = await pathService.getShortestPath(startCode, endCode);

    if (pathData != null && pathData['result'] != null) {
      final result = pathData['result'];
      final List<dynamic> stationsList = result['stations'] ?? [];
      final List<dynamic> routeList = result['route'] ?? [];

      // ✅ station이 포함된 구간 찾기
      String? routeStartStation;

      String _normalizeStationName(String name) {
        return name.replaceAll(RegExp(r'\(.*?\)'), '').replaceAll(RegExp(r'\s*역$'), '').trim();
      }

      for (final stationItem in stationsList) {
        final start = _normalizeStationName(stationItem['startName']);
        final end = _normalizeStationName(stationItem['endName']);
        final current = _normalizeStationName(station);

        if (start == current || end == current) {
          routeStartStation = stationItem['startName'];
          break;
        }
      }

      // ✅ 그 구간이 속한 route 찾기
      if (routeStartStation != null) {
        for (final route in routeList) {
          final routeStart = route['startName'];
          final dir = route['direction'];
          if (dir != '상행' && dir != '하행') continue;
          if (_normalizeStationName(routeStart) == _normalizeStationName(routeStartStation!)) {
            updnLine = dir;
            break;
          }
        }
      }

      // fallback: 그래도 못 찾으면 첫 번째 route 방향 사용
      if (updnLine == null && routeList.isNotEmpty) {
        final fallbackDir = routeList[0]['direction'];
        if (fallbackDir == '상행' || fallbackDir == '하행') {
          updnLine = fallbackDir;
        }
      }
    }


    if (updnLine == null) {
      print('❌ 방향 판단 실패: 경로 API에서 direction을 찾을 수 없음');
      return;
    }
    final validDirections = ['상행', '하행'];
    if (!validDirections.contains(updnLine)) {
      print('❌ 혼잡도 예측 중단: direction 값이 유효하지 않음 → $updnLine');
      return;
    }

    final uri = Uri.parse(
        'http://43.200.50.230/api/v1/congestion/predict/$startCode'
            '?line=${int.tryParse(lineCode ?? "0") ?? 0}'
            '&updnLine=${["상행", "내선"].contains(updnLine) ? "0" : "1"}'
            '&hour=${departureTime.hour}'
            '&minute=${departureTime.minute}'
            '&dayType=$selectedDayType'
            '&month=${DateTime.now().month}'
    );

    print('➡️ lineCode: $lineCode');
    print('➡️ stationCode: $startCode');
    print('➡️ hour: ${departureTime.hour}, minute: ${departureTime.minute}');
    print('➡️ month: ${DateTime.now().month}');


    final response = await http.post(
      uri,
      headers: {'accept': '*/*'},
      body: '', // 빈 body 필요
    );
    try {
      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        print('📦 혼잡도 응답 전체: $json');

        final rawPredictions = json['result']['predictions'];
        if (rawPredictions != null && rawPredictions is Map) {
          final result = <String, Map<String, dynamic>>{};

          rawPredictions.forEach((key, value) {
            if (value is Map && value.containsKey('level') && value.containsKey('percentage')) {
              result[key] = {
                'level': value['level'],
                'percentage': value['percentage'],
              };
            }
          });



          setState(() {
            congestionData = result; // ✅ 현재 시간 기준 예측은 여기로
          });
          await fetchCongestionPredictionFuture();
        } else {
          print('❌ predictions가 null이거나 Map 타입이 아님: $rawPredictions');
        }
      } else {
        print('❌ API 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 예외 발생: $e');
    }
  }

  Future<void> fetchCongestionPredictionFuture() async {
    print('✅ fetchCongestionPrediction() 호출됨');
    print('🔍 line: $line');
    print('🔍 station: $station');

    final lineCode = _getLineCodeByName(line);
    if (!(["2", "3", "4", "5", "6", "7", "8"].contains(lineCode))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 40, color: Colors.black),
                  const SizedBox(height: 16),
                  const Text(
                    '예측 혼잡도를 지원하지 않는 경로입니다.',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '지하철 2~8호선의 혼잡도만 제공됩니다.',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showRealTimeModal(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4262C5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('실시간'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Future.delayed(const Duration(milliseconds: 100), () {
                              if (mounted) {
                                Navigator.of(context).maybePop();
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE0E0E0),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('확인'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

      });
      return;
    }

    final stationService = ApiStationService();
    final startCode = (await stationService.getFrCodeByStationName(station))?.toString();
    final endCode = (await stationService.getFrCodeByStationName(destination))?.toString();


    if (startCode == null || endCode == null) {
      print('❌ 혼잡도 예측: stationCode를 찾을 수 없습니다.');
      return;
    }

    String? updnLine;

    final pathService = PathService();
    final pathData = await pathService.getShortestPath(startCode, endCode);

    if (pathData != null && pathData['result'] != null) {
      final result = pathData['result'];
      final List<dynamic> stationsList = result['stations'] ?? [];
      final List<dynamic> routeList = result['route'] ?? [];

      // ✅ station이 포함된 구간 찾기
      String? routeStartStation;

      String _normalizeStationName(String name) {
        return name.replaceAll(RegExp(r'\(.*?\)'), '').replaceAll(RegExp(r'\s*역$'), '').trim();
      }

      for (final stationItem in stationsList) {
        final start = _normalizeStationName(stationItem['startName']);
        final end = _normalizeStationName(stationItem['endName']);
        final current = _normalizeStationName(station);

        if (start == current || end == current) {
          routeStartStation = stationItem['startName'];
          break;
        }
      }


      // ✅ 그 구간이 속한 route 찾기
      if (routeStartStation != null) {
        for (final route in routeList) {
          final routeStart = route['startName'];
          final dir = route['direction'];
          if (dir != '상행' && dir != '하행') continue;
          if (routeStart == routeStartStation) {
            updnLine = dir;
            break;
          }

        }
      }

      // fallback: 그래도 못 찾으면 첫 번째 route 방향 사용
      if (updnLine == null && routeList.isNotEmpty) {
        final fallbackDir = routeList[0]['direction'];
        if (fallbackDir == '상행' || fallbackDir == '하행') {
          updnLine = fallbackDir;
        }
      }
    }


    if (updnLine == null) {
      print('❌ 방향 판단 실패: 경로 API에서 direction을 찾을 수 없음');
      return;
    }
    final validDirections = ['상행', '하행'];
    if (!validDirections.contains(updnLine)) {
      print('❌ 혼잡도 예측 중단: direction 값이 유효하지 않음 → $updnLine');
      return;
    }

    final futureTime = TimeOfDay(
      hour: (departureTime.hour + ((departureTime.minute + predictionOffsetMinutes) ~/ 60)) % 24,
      minute: (departureTime.minute + predictionOffsetMinutes) % 60,
    );
    final futureUri = Uri.parse(
        'http://43.200.50.230/api/v1/congestion/predict/$startCode'
            '?line=${int.tryParse(lineCode ?? "0") ?? 0}'
            '&updnLine=${["상행", "내선"].contains(updnLine) ? "0" : "1"}'
            '&hour=${futureTime.hour}'
            '&minute=${futureTime.minute}'
            '&dayType=$selectedDayType'
            '&month=${DateTime.now().month}'
    );

    print('🚇 direction: $updnLine → 전송된 updnLine: ${["상행", "내선"].contains(updnLine) ? "0" : "1"}');

    final response = await http.post(
      futureUri,
      headers: {'accept': '*/*'},
      body: '', // 빈 body 필요
    );

    try {
      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        print('📦 혼잡도 응답 전체: $json');

        final rawPredictions = json['result']['predictions'];
        if (rawPredictions != null && rawPredictions is Map) {
          final result = <String, Map<String, dynamic>>{};

          rawPredictions.forEach((key, value) {
            if (value is Map && value.containsKey('level') && value.containsKey('percentage')) {
              result[key] = {
                'level': value['level'],
                'percentage': value['percentage'],
              };
            }
          });


          final sortedResult = Map.fromEntries(
            result.entries.toList()
              ..sort((a, b) {
                final numA = int.tryParse(a.key.split('_').last) ?? 0;
                final numB = int.tryParse(b.key.split('_').last) ?? 0;
                return numA.compareTo(numB);
              }),
          );
          print('📦 result: $sortedResult');


          setState(() {
            congestionDataFuture = result;
          });
        } else {
          print('❌ predictions가 null이거나 Map 타입이 아님: $rawPredictions');
        }
      } else {
        print('❌ API 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 예외 발생: $e');
    }
    print('➡️ lineCode: $lineCode');
    print('➡️ stationCode: $startCode');
    print('➡️ hour: ${futureTime.hour}, minute: ${futureTime.minute}');
    print('➡️ month: ${DateTime.now().month}');
    print('🕐 [10분 후 요청] futureTime: ${futureTime.hour}:${futureTime.minute}');
  }

  String? _getLineCodeByName(String name) {
    try {
      final match = subwayLines.firstWhere((lineInfo) => lineInfo.name == name);
      return match.lineCode;
    } catch (e) {
      return null;
    }
  }



  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: departureTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Color(0xFFFFFFFF), // 배경
              hourMinuteTextColor: Color(0xFF4262C5),
              dialHandColor: Color(0xFF4262C5), // 시침/분침
              dialBackgroundColor: Color(0xFFE0E7FF), // 다이얼 배경
              entryModeIconColor: Color(0xFF4262C5),
              dayPeriodColor: Color(0xFFDCE3FF), // AM/PM 배경
              dayPeriodTextColor: Color(0xFF223B85), // AM/PM 글자
              hourMinuteColor: Color(0xFFDCE3FF), // 시/분 배경
            ),
            colorScheme: ColorScheme.light(
              primary: Color(0xFF4262C5), // 주요 강조색
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF4262C5),
              ),
            ),
          ),
          child: child!,
        );
      },

    );

    if (picked != null) {
      setState(() {
        departureTime = picked;

        final depDate = DateTime(0, 1, 1, picked.hour, picked.minute);
        final durParts = duration.split(RegExp(r'[시간분\s]+')).where((e) => e.isNotEmpty).toList();
        int durHour = durParts.length == 2 ? int.parse(durParts[0]) : 0;
        int durMin = durParts.length == 2 ? int.parse(durParts[1]) : int.parse(durParts[0]);

        final arrDate = depDate.add(Duration(hours: durHour, minutes: durMin));
        arrivalTime = TimeOfDay(hour: arrDate.hour, minute: arrDate.minute);
      });
      fetchCongestionPrediction();
    }

  }

  String _getArrivalTimeFormatted24() {
    final depDate = DateTime(0, 1, 1, departureTime.hour, departureTime.minute);
    final durParts = duration.split(RegExp(r'[시간분\s]+')).where((e) => e.isNotEmpty).toList();

    int durHour = durParts.length == 2 ? int.parse(durParts[0]) : 0;
    int durMin = durParts.length == 2 ? int.parse(durParts[1]) : int.parse(durParts[0]);

    final arrDate = depDate.add(Duration(hours: durHour, minutes: durMin));
    return '${arrDate.hour.toString().padLeft(2, '0')}:${arrDate.minute.toString().padLeft(2, '0')}';
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '혼잡도 예측',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 8), // RouteResult와 동일한 위치
        child: FloatingActionButton(
          onPressed: () {
            final now = TimeOfDay.now();
            setState(() {
              departureTime = now;
              // arrivalTime = updatedArrival;
            });
          },
          backgroundColor: const Color(0xFF4262C5),
          shape: const CircleBorder(),
          child: const Icon(
            Icons.refresh,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),


      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        duration,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '환승 ${transferCount}회',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildRadioOption('평일'),
                      const SizedBox(width: 4),
                      _buildRadioOption('토요일'),
                      const SizedBox(width: 4),
                      _buildRadioOption('일요일'),
                    ],
                  ),
                ],
              ),


              const SizedBox(height: 6),
// ✅ 2. 출발/도착 시간 박스
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FF),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => _selectTime(context),
                      child: Text(
                        '출발 ${departureTime.format(context)}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '도착 ${arrivalTime.format(context)}',

                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ✅ 시간 표시

              _buildRouteStep(
                context: context,
                time: _formatTime24(departureTime),
                station: originalStation,
                line: line,
                color: color,
                fastTransfer: fastTransfer,
                icon: icon,
              ),

              _buildArrivalOrTransferStep(
                line: line,
                station: actualArrival,
                time: _formatTime24(arrivalTime),
              ),


              // ✅ 혼잡도 범례 추가!
              const SizedBox(height: 75),
              _buildCongestionLegend(),
            ],
          ),
        ),
      ),

    );
  }
  Widget _buildRadioOption(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: label,
          groupValue: selectedDayType,
          onChanged: (value) {
            setState(() {
              selectedDayType = value!;
              fetchCongestionPrediction(); // 요일 바꾸면 다시 예측
            });
          },
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  String _formatTime24(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildArrivalOrTransferStep({
    required String line,
    required String station,
    required String time,
  }) {
    if (line == '1호선') {
      return _buildArrivalStep(
        time: time,
        station: station,
      );
    } else {
      return _buildTransferStep(
        time: time,
        station: station,
        distance: '',
        icon: Icons.location_on,
        color: Colors.red,
      );
    }
  }
  void _showPredictionOffsetPicker(BuildContext context) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('예측 시간 선택'),
        backgroundColor: Colors.white,
        children: List.generate(6, (i) {
          final minute = (i + 1) * 10;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, minute),
            child: Text('$minute분 후'),
          );
        }),
      ),
    );

    if (result != null && result != predictionOffsetMinutes) {
      setState(() {
        predictionOffsetMinutes = result;
      });
      fetchCongestionPrediction();
    }
  }


  void _showRealTimeModal(BuildContext context) {
    final lineCode = _getLineCodeByName(line);
    if (!(["2", "3", "4", "5", "6", "7", "8", "9"].contains(lineCode))) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40, color: Colors.black),
                const SizedBox(height: 16),
                const Text(
                  '실시간 혼잡도를 지원하지 않는 경로입니다.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  '지하철 2~9호선의 혼잡도만 제공됩니다.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE0E0E0),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('확인'),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    // ✅ 2~9호선이면 정상적으로 모달 실행
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RealTimeBottomSheet(
        color: color,
        line: line,
        station: station,
        fastTransfer: fastTransfer,
        icon: icon,
        duration: duration,
        arrivalStation: actualArrival,
        arrivalTime: _getArrivalTimeFormatted24(),
        sectionDurations: [14, 27],
        carsList: [],
        arrivalTimes: [],
      ),
    );
  }




  Widget _buildArrivalStep({
    required String time,
    required String station,
  }) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 60, right: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  _buildCircularIcon(Icons.location_on, Colors.redAccent), // 📍 종착역 아이콘
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row( // ✅ 하차 텍스트와 아이콘을 하나의 그룹으로 묶기
                            children: [
                              Text(
                                '$station 하차',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4), // 간격
                              Icon(
                                Icons.help_outline,
                                size: 18,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  ],
                ),
              ),

            ],
          ),
        ),
        Positioned(
          left: 10,
          top: 14,
          child: Text(
            _getArrivalTimeFormatted24(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildRouteStep({
    required BuildContext context,
    required String time,
    required String station,
    required String line,
    required Color color,
    required String fastTransfer,
    required IconData icon,
  }) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 60, right: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  _buildCircularIcon(icon, color),
                  Container(
                    width: 6,
                    height: 300,
                    color: color,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Transform.translate(
                            offset: const Offset(0, -6),
                            child: Text(
                              line,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final trainInfoList = await printRealTimeTrainNos();
                              // 반드시 trainNo만 추출해서 List<String>으로 변환!
                              final trainNos = trainInfoList.map((info) => info['trainNo']!).toList();
                              final arrivalTimes = trainInfoList.map((info) => info['arrivalTime']!).toList();
                              final carsList = await fetchRealTimeCongestionCarsList(trainNos);
                              print('🚇 실시간 혼잡도 carsList: $carsList');
                              print('🚇 실시간 혼잡도 carsList: $carsList');
                              if (carsList.isNotEmpty) {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                  ),
                                  builder: (context) => RealTimeBottomSheet(
                                    color: color,
                                    line: line,
                                    station: station,
                                    fastTransfer: fastTransfer,
                                    icon: icon,
                                    duration: duration,
                                    arrivalStation: actualArrival,
                                    arrivalTime: _getArrivalTimeFormatted24(),
                                    sectionDurations: [14, 27],
                                    carsList: carsList,
                                    arrivalTimes: arrivalTimes,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('실시간 혼잡도 데이터가 없습니다.')),
                                );
                              }
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Colors.black),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                            ),
                            child: const Text(
                              '실시간',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // 👇 여기만 Transform으로 감쌈
                      Transform.translate(
                        offset: const Offset(0, -16.5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$station', // ✅ 이미 승차 제거된 상태로 station 변수에 저장됨
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              fastTransfer,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),
                      _buildCongestionGraph(),
                    ],
                  )
              ),
            ],
          ),
        ),
        Positioned(
          left: 10,
          top: 8,
          child: Text(
            _formatTime24(departureTime),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        Positioned(
          left: 32,
          top: 175,
          child: Text(
            duration,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  // 혼잡도 그래프 위젯
  Widget _buildCongestionGraph() {
    final currentInfo = _getColorsWithRecommendations(congestionData);
    final futureInfo = _getColorsWithRecommendations(congestionDataFuture);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        _buildTrainRow(
          label: '현재 시간',
          seatColors: currentInfo['colors'],
          recommendedIndexes: currentInfo['recommendations'],
        ),
        const SizedBox(height: 8),
        _buildTrainRow(
          label: '$predictionOffsetMinutes분 후',
          seatColors: futureInfo['colors'],
          recommendedIndexes: futureInfo['recommendations'],
          onLabelTap: () => _showPredictionOffsetPicker(context),
        ),
      ],
    );

  }
  List<Color> _getColors(Map<String, String> data) {
    final keys = data.keys.toList()
      ..sort((a, b) {
        final numA = int.tryParse(a.split('_').last) ?? 0;
        final numB = int.tryParse(b.split('_').last) ?? 0;
        return numA.compareTo(numB);

      });

    return keys.map((key) {
      switch (data[key]) {
        case 'RELAXED': return const Color(0xFF4863EC);
        case 'NORMAL': return const Color(0xFF52B93E);
        case 'WARNING': return const Color(0xFFEED906);
        case 'CROWDED': return const Color(0xFFF70505);
        default: return Colors.grey.shade300;
      }
    }).toList();

  }


  Map<String, dynamic> _getColorsWithRecommendations(Map<String, Map<String, dynamic>> data) {

    final keys = data.keys.toList()
      ..sort((a, b) {
        final numA = int.tryParse(a.split('_').last) ?? 0;
        final numB = int.tryParse(b.split('_').last) ?? 0;
        return numA.compareTo(numB);
      });

    final percentages = keys.map((k) => (data[k]?['percentage'] as num?)?.toDouble() ?? 1000).toList();

    final minIndexes = List.generate(percentages.length, (i) => i)
      ..sort((a, b) => percentages[a].compareTo(percentages[b]));

    final recommendedIndexes = minIndexes.take(2).toSet();
    print('📊 칸별 혼잡도 percentage: $percentages');
    print('✅ 추천 인덱스: $recommendedIndexes');
    final colors = keys.map((key) {
      final level = data[key]?['level'];
      switch (level) {
        case 'RELAXED': return const Color(0xFF4863EC);
        case 'NORMAL': return const Color(0xFF52B93E);
        case 'WARNING': return const Color(0xFFEED906);
        case 'CROWDED': return const Color(0xFFF70505);
        default: return Colors.grey.shade300;
      }
    }).toList();

    return {
      'colors': colors,
      'recommendations': recommendedIndexes,
    };
  }
  Widget _buildCongestionLegend() {
    return Padding(
      padding: const EdgeInsets.only(top: 24, left:52),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLegendItem(color: Color(0xFF4863EC), label: '여유'),
              const SizedBox(width: 8),
              _buildLegendItem(color: Color(0xFF52B93E), label: '보통'),
              const SizedBox(width: 8),
              _buildLegendItem(color: Color(0xFFEED906), label: '주의'),
              const SizedBox(width: 8),
              _buildLegendItem(color: Color(0xFFF70505), label: '혼잡'),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.help_outline, size: 20, color: Colors.black54),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: const Color(0xFFF7F6FA),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 320), // ⬅️ 팝업 너비 확대
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '안내',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF222222),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '◼︎ "10분 후"는 기본값이며 텍스트를 탭하면 \n  예측 시점을 10분 단위로 변경할 수 있습니다.',
                                style: TextStyle(fontSize: 14, height: 1.6),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '◼︎ "▲"는 예측 혼잡도 퍼센트(%)가 가장 낮은 \n  두 칸을 표시합니다.',
                                style: TextStyle(fontSize: 14, height: 1.6),
                              ),
                              const SizedBox(height: 20),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    minimumSize: Size(0, 30),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text(
                                    '닫기',
                                    style: TextStyle(
                                      color: Color(0xFF3A45B7),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

            ],
          ),
        ],
      ),
    );
  }


  Widget _buildLegendItem({required Color color, required String label}) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.black, fontSize: 12),
        ),
      ],
    );
  }


  Widget _buildLegendCircle({required Color color}) {
    return Container(
      width: 36,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }



  Widget _buildTrainRow({
    required String label,
    required List<Color> seatColors,
    required Set<int> recommendedIndexes,
    VoidCallback? onLabelTap,
  }) {
    if (seatColors.isEmpty) return const SizedBox();

    final boxCount = seatColors.length;
    final boxWidth = 22.0;
    final spacing = 2.0;
    final totalWidth = boxCount * boxWidth + (boxCount - 1) * spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: totalWidth,
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 4), // 👈 살짝 왼쪽으로 이동
              child: GestureDetector(
                onTap: onLabelTap,
                behavior: HitTestBehavior.translucent,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF111111),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 4),
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(seatColors.length, (index) {
                final isFirst = index == 0;
                final isLast = index == seatColors.length - 1;
                final box = isFirst
                    ? _buildLeftHalfCircle(seatColors[index], index)
                    : isLast
                    ? _buildRightHalfCircle(seatColors[index], index)
                    : _buildSeatBox(seatColors[index], index);

                return Column(
                  children: [
                    box,
                    const SizedBox(height: 2),
                    Opacity(
                      opacity: recommendedIndexes.contains(index) ? 1.0 : 0.0,
                      child: Transform.scale(
                        scaleY: 0.7,
                        child: const Text(
                          '▲',
                          style: TextStyle(fontSize: 23),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),

      ],
    );

  }




  Widget _buildSeatBox(Color color, int index) {
    return Container(
      width: 22,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Align(
        alignment: Alignment(0, 0.3), // 👈 y축 기준으로 아래로 2픽셀 정도 내림
        child: Text(
          '${index + 1}',
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }


  Widget _buildLeftHalfCircle(Color color, int index) {
    return Container(
      width: 25,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          bottomLeft: Radius.circular(12),
          topRight: Radius.circular(7),
          bottomRight: Radius.circular(5),
        ),
      ),
      child: index == 0
          ? Align(
        alignment: const Alignment(0.05, 0.3), // 살짝 오른쪽 + 아래
        child: Text(
          '${index + 1}',
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      )
          : Align(
        alignment: const Alignment(0, 0.3), // 가운데 정렬에서 아래로
        child: Text(
          '${index + 1}',
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),

    );
  }

  Widget _buildRightHalfCircle(Color color, int index) {
    return Container(
      width: 22,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          bottomLeft: Radius.circular(5),
          topRight: Radius.circular(5),
          bottomRight: Radius.circular(5),
        ),
      ),
      child: Align(
        alignment: Alignment(0, 0.3), // 👈 y축 기준으로 아래로 2픽셀 정도 내림
        child: Text(
          '${index + 1}',
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),

    );
  }


  Widget _buildTransferStep({
    required String time,
    required String station,
    required String distance,
    required IconData icon,
    required Color color,
  }) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 60, right: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  _buildCircularIcon(icon, color),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0), // 원하는 만큼 조절 가능
                      child: Text(
                        '$station 하차',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Text(
                      distance,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 10,
          top: 6.5,
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  // ✅ 원형 아이콘 생성 함수 복제
  Widget _buildCircularIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}