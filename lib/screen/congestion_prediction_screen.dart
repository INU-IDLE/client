import 'package:flutter/material.dart';
import 'real_time_bottom_sheet.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rushcutter/services/api_station_service.dart';
import 'package:rushcutter/data/line_mapping.dart';




// ✅ 위젯 클래스: 비워두기
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
  bool _isInitialized = false;
  Map<String, String> congestionData = {}; // ✅ 여기로 옮겨야 함

  @override
  void initState() {
    super.initState();

  }
  late String originalStation;

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

    final lineCode = _getLineCodeByName(line);
    if (!(["2", "3", "4", "5", "6", "7", "8"].contains(lineCode))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('혼잡도 예측 불가'),
            content: const Text('해당 노선은 혼잡도 예측을 지원하지 않습니다.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) {
                      Navigator.of(context).maybePop();
                    }
                  });
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      });
      return;
    }

    final stationService = ApiStationService();
    final stationCode = await stationService.getFrCodeByStationName(station);

    print('➡️ lineCode: $lineCode');
    print('➡️ stationCode: $stationCode');
    print('➡️ hour: ${departureTime.hour}, minute: ${departureTime.minute}');
    print('➡️ month: ${DateTime.now().month}');

    if (lineCode == null || stationCode == null) {
      print('❌ 혼잡도 예측: lineCode 또는 stationCode를 찾을 수 없습니다.');
      return;
    }

    final uri = Uri.parse(
        'http://43.200.50.230/api/v1/congestion/predict/$stationCode'
            '?line=$lineCode'
            '&updnLine=상행'
            '&hour=${departureTime.hour}'
            '&minute=${departureTime.minute}'
            '&dayType=평일'
            '&month=${DateTime.now().month}'
    );
    final response = await http.post(
      uri,
      headers: {'accept': '*/*'},
      body: '', // ✅ 빈 body 필요
    );

    try {

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        print('📦 혼잡도 응답 전체: $json');

        final rawPredictions = json['result']['predictions'];
        if (rawPredictions != null && rawPredictions is Map) {
          final result = Map<String, String>.from(rawPredictions);
          print('📦 result: $result');

          setState(() {
            congestionData = result;
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
              backgroundColor: Colors.white,
              hourMinuteTextColor: Colors.blue[800],
              dialHandColor: Colors.blue,
              dialBackgroundColor: Colors.blue[50],
              entryModeIconColor: Colors.blue[700],
              dayPeriodColor: Colors.blue[100],
              dayPeriodTextColor: Colors.blue[900],
              hourMinuteColor: Colors.blue[100],
            ),
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
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

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final now = TimeOfDay.now();
          final nowDateTime = DateTime.now();

          final durParts = duration.split(RegExp(r'[시간분\s]+')).where((e) => e.isNotEmpty).toList();
          int durHour = durParts.length == 2 ? int.parse(durParts[0]) : 0;
          int durMin = durParts.length == 2 ? int.parse(durParts[1]) : int.parse(durParts[0]);

          final arrivalDateTime = nowDateTime.add(Duration(hours: durHour, minutes: durMin));
          final updatedArrival = TimeOfDay(hour: arrivalDateTime.hour, minute: arrivalDateTime.minute);

          setState(() {
            departureTime = now;
            //arrivalTime = updatedArrival;
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        duration,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(top: 10, left: 6), // ← 여기 숫자로 살짝 내려줌
                        child: Text(
                          '환승 1회',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),




              const SizedBox(height: 4),


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
  String _getArrivalStation() {
    if (line == '1호선') {
      return '구일역';
    } else if (line == '인천1호선') {
      return '부평역';
    } else {
      return '도착역';
    }
  }
  String _getArrivalTimeFormatted(BuildContext context) {
    final depDate = DateTime(0, 1, 1, departureTime.hour, departureTime.minute);
    final durParts = duration.split(RegExp(r'[시간분\s]+')).where((e) => e.isNotEmpty).toList();

    int durHour = durParts.length == 2 ? int.parse(durParts[0]) : 0;
    int durMin = durParts.length == 2 ? int.parse(durParts[1]) : int.parse(durParts[0]);

    final arrDate = depDate.add(Duration(hours: durHour, minutes: durMin));
    final arrTime = TimeOfDay(hour: arrDate.hour, minute: arrDate.minute);
    return arrTime.format(context);
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


  void _showRealTimeModal(BuildContext context) {
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
                      padding: const EdgeInsets.only(top: 6.0), // 원하는 만큼 조절 가능
                      child: Text(
                        '$station 하차',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
                          onPressed: () => _showRealTimeModal(context),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Colors.black),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

                    const SizedBox(height: 12),
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
          top: 160,
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
    final carKeys = congestionData.keys.toList()..sort(); // 🚉 응답 기반으로 동적으로 칸 구성


    List<Color> getColors() {
      return carKeys.map((key) {
        print('🚈 $key: ${congestionData[key]}');
        switch (congestionData[key]) {
          case 'RELAXED': return const Color(0xFF2E2FFB); // 여유
          case 'NORMAL': return const Color(0xFF51E817); // 보통
          case 'CROWDED': return const Color(0xFFFFE619); // 주의
          case 'CONGESTED': return const Color(0xFFFB3030); // 혼잡
          default: return Colors.grey.shade300; // 예측 안 된 경우
        }
      }).toList();
    }

    final seatColors = getColors();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12)



        ,
        _buildTrainRow(label: '예측', seatColors: seatColors),
      ],
    );
  }


  Widget _buildCongestionLegend() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          const Text(
            '혼잡도는 다음과 같이 4단계로 분류했습니다.',
            style: TextStyle(fontSize: 12, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendCircle(color: Color(0xFFFB3030)), // 빨강
              const SizedBox(width: 8),
              _buildLegendCircle(color: Color(0xFFFFE619)), // 노랑
              const SizedBox(width: 8),
              _buildLegendCircle(color: Color(0xFF51E817)), // 초록
              const SizedBox(width: 8),
              _buildLegendCircle(color: Color(0xFF2E2FFB)), // 파랑
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendCircle({required Color color}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }


  Widget _buildTrainRow({
    required String label,
    required List<Color> seatColors,
  })
  {

    if (seatColors.isEmpty) {
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // 🚋 그래프 부분
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLeftHalfCircle(seatColors.first),
                ...seatColors
                    .sublist(1, seatColors.length - 1)
                    .map((color) => _buildSeatBox(color))
                    .toList(),
                _buildRightHalfCircle(seatColors.last),
              ],
            ),
          ),

          // 🕒 텍스트를 위에 오른쪽 정렬로 띄우기
          Positioned(
            top: -6,
            right: 30,
            child: Container(
              width: 60,
              height: 15,
              alignment: Alignment.centerRight,
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
        ],
      ),
    );
  }




  Widget _buildSeatBox(Color color) {
    return Container(
      width: 20,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5), // 👈 모든 모서리 5
      ),
    );
  }


  Widget _buildLeftHalfCircle(Color color) {
    return Container(
      width: 22,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          bottomLeft: Radius.circular(15),
          topRight: Radius.circular(5),
          bottomRight: Radius.circular(5),
        ),
      ),
    );
  }
  Widget _buildRightHalfCircle(Color color) {
    return Container(
      width: 22,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(5),
          bottomLeft: Radius.circular(5),
          topRight: Radius.circular(15),
          bottomRight: Radius.circular(15),
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