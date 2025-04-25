import 'package:flutter/material.dart';
import 'real_time_bottom_sheet.dart';

class CongestionPredictionScreen extends StatefulWidget {
  const CongestionPredictionScreen({Key? key}) : super(key: key);

  @override
  State<CongestionPredictionScreen> createState() => _CongestionPredictionScreenState();
}

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
  bool _isInitialized = false;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};

    line = args['line'];
    station = args['station'];
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

    _isInitialized = true;
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
            arrivalTime = updatedArrival;
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
        child: SingleChildScrollView( // 🔥 스크롤 추가
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4), // 또는 그냥 제거

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


              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FF),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.1 * 255).toInt()),

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
                      '도착 ${_getArrivalTimeFormatted(context)}',

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


              _buildRouteStep(
                context: context,
                time: _formatTime24(departureTime),
                station: station,
                line: line,
                color: color,
                fastTransfer: fastTransfer,
                icon: icon,
              ),

              _buildArrivalOrTransferStep(
                line: line,
                station: _getArrivalStation(),
                time: _formatTime24(arrivalTime),
              ),



              const SizedBox(height: 75),
              _buildCongestionLegend(),
            ],
          ),
        ),
      ),

    );
  }
// CongestionPredictionScreen 내부에 추가
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
        distance: '도보 316m',
        icon: Icons.directions_walk,
        color: Colors.grey,
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
                    Text(
                      '$station 하차',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
                    // 🔹 여기에 라인 + 실시간 버튼 한 줄로 정렬
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          line,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
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

                    Text(station, style: const TextStyle(fontSize: 14)),
                    Text(fastTransfer, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 12),
                    _buildCongestionGraph(),
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
            _formatTime24(departureTime),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        _buildTrainRow(
          label: '5분 후',
          seatColors: [
            Color(0xFFFFE619), Color(0xFFFB3030), Color(0xFFFB3030),
            Color(0xFFFFE619), Color(0xFF51E817), Color(0xFF51E817),
            Color(0xFF2E2FFB), Color(0xFF2E2FFB), Color(0xFFFFE619),
          ],
        ),
        const SizedBox(height: 15),
        _buildTrainRow(
          label: '10분 후',
          seatColors: [
            Color(0xFFFFE619), Color(0xFFFFE619), Color(0xFFFB3030),
            Color(0xFF51E817), Color(0xFF51E817), Color(0xFF51E817),
            Color(0xFF2E2FFB), Color(0xFF2E2FFB), Color(0xFFFFE619),
          ],
        ),
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
              _buildLegendCircle(color: Color(0xFFFB3030)),
              const SizedBox(width: 8),
              _buildLegendCircle(color: Color(0xFFFFE619)),
              const SizedBox(width: 8),
              _buildLegendCircle(color: Color(0xFF51E817)),
              const SizedBox(width: 8),
              _buildLegendCircle(color: Color(0xFF2E2FFB)),
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
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
        borderRadius: BorderRadius.circular(5),
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
                  // 필요하다면 선도 추가 가능
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
          top: 14,
          child: Text(
            _formatTime24(departureTime),
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