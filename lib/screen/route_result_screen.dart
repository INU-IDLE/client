import 'package:flutter/material.dart';
import 'package:rushcutter/screen/real_time_bottom_sheet.dart';
import 'package:rushcutter/providers/saved_route_provider.dart';
import 'package:provider/provider.dart';
import 'package:rushcutter/models/saved_route.dart';

class RouteResultScreen extends StatefulWidget {
  final String departure;
  final String arrival;

  const RouteResultScreen({
    required this.departure,
    required this.arrival,
    Key? key,
  }) : super(key: key);


  @override
  State<RouteResultScreen> createState() => _RouteResultScreenState();
}
class _RouteResultScreenState extends State<RouteResultScreen> {
  late TimeOfDay departureTime;
  late TimeOfDay arrivalTime;
  bool isFavorite = false;

  String get durationText {
    DateTime dep = DateTime(0, 1, 1, departureTime.hour, departureTime.minute);
    DateTime arr = DateTime(0, 1, 1, arrivalTime.hour, arrivalTime.minute);

    if (arr.isBefore(dep)) {
      // 도착 시간이 출발보다 이른 경우 → 다음날 도착으로 보정
      arr = arr.add(const Duration(days: 1));
    }

    final duration = arr.difference(dep);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours > 0 ? '$hours시간 ' : ''}$minutes분';
  }

  @override
  void initState() {
    super.initState();

    departureTime = TimeOfDay.now();

    final now = DateTime.now();
    final estimatedArrival = DateTime(
      now.year,
      now.month,
      now.day,
      departureTime.hour,
      departureTime.minute,
    ).add(const Duration(minutes: 63)); // 🚆 예시: 도착 시간은 1시간 3분 후

    arrivalTime = TimeOfDay(
      hour: estimatedArrival.hour,
      minute: estimatedArrival.minute,
    );
  }


  String _formatTime24(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget build(BuildContext context) {
    final route = SavedRoute(
      from: widget.departure,
      to: widget.arrival,
      details: '인천1호선, 1호선 (환승 1회)',
    );
    final provider = Provider.of<SavedRouteProvider>(context);
    final isSaved = provider.isSaved(route);
    return Scaffold(
      backgroundColor: Colors.white, // ✅ 페이지 전체 배경 흰색 적용
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '길찾기',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),


      floatingActionButton: Container(
        width: 56,
        height: 56,
        margin: const EdgeInsets.only(bottom: 16, right: 8), // 💡 여백 조절(선택)
        child: FloatingActionButton(
          onPressed: () {
            final now = TimeOfDay.now();
            final nowDateTime = DateTime.now();

            final estimatedArrival = nowDateTime.add(const Duration(minutes: 63)); // 🚆 다시 예시

            setState(() {
              departureTime = now;
              arrivalTime = TimeOfDay(
                hour: estimatedArrival.hour,
                minute: estimatedArrival.minute,
              );
            });
          },

          backgroundColor: const Color(0xFF4262C5), // 💙 동일 색상
          shape: const CircleBorder(), // ⭕ 완전한 원형
          child: const Icon(
            Icons.refresh,
            color: Colors.white,
            size: 28, // 🎯 아이콘 크기도 통일
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,


      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ 상단 간격 줄이기
            const SizedBox(height: 4),

            // ✅ 시간 + 환승 정보
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      durationText,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(top: 10, left: 6),
                      child: const Text(
                        '환승 1회',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  iconSize: 32,
                  icon: Icon(
                    isSaved ? Icons.star : Icons.star_border,
                    color: isSaved ? Colors.amber : Colors.grey,
                  ),
                  onPressed: () {
                    provider.toggle(route);
                  },
                ),
              ],
            ),

            const SizedBox(height: 4),

            // ✅ 출발/도착 시간 박스
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
                    onTap: () => _selectTime(context, true),
                    child: Text(
                      '출발 ${departureTime.format(context)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    child: Text(
                      '도착 ${arrivalTime.format(context)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),


            // ✅ 노선 경로 표시
            // ✅ 노선 경로 표시
            Expanded(
              child: ListView(
                children: [
                  _buildRouteStep(
                    time: _formatTime24(departureTime),
                    station: '송도달빛축제공원역 승차',
                    line: '인천1호선',
                    color: const Color(0xFF9CBCDD),
                    duration: durationText,
                    stationCount: '19개 역 이동',
                    destination: '계양행',
                    fastTransfer: '빠른 환승 4-4',
                    icon: Icons.directions_subway,
                    context: context, // 👉 context 전달
                  ),
                  _buildTransferStep(
                    time: '11:46',
                    station: '부평역 하차',
                    distance: '도보 316m',
                  ),
                  _buildRouteStep(
                    time: '11:51',
                    station: '부평역 승차',
                    line: '1호선',
                    color: const Color(0xFF434C9C),
                    duration: durationText,
                    stationCount: '10개 역 이동',
                    destination: '구로행',
                    fastTransfer: '빠른 하차 1-1, 10-4',
                    icon: Icons.directions_subway,
                    context: context, // 👉 context 전달
                  ),
                  _buildArrivalStep(
                    time: _formatTime24(arrivalTime),// ✅ 도착 시간도 동적으로!
                    station: '구일역 하차',
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildCongestionButton(BuildContext context, {
    required String line,
    required String station,
    required String destination,
    required String fastTransfer,
    required String time,
    required String duration,
    required String stationCount,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        if (line == '인천1호선') {
          // ✅ 인천1호선은 팝업 띄우기
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.error_outline, size: 40, color: Colors.black),
                  SizedBox(height: 16),
                  Text(
                    '혼잡도를 지원하지 않는 경로입니다.\n지하철 2~9호선의 혼잡도만 제공됩니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.only(bottom: 12),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                // ✅ 실시간 버튼 → 모달 띄움
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // 먼저 다이얼로그 닫고
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
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4262C5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: const Text('실시간', style: TextStyle(color: Colors.white)),
                ),

                // ✅ 확인 버튼 → 그냥 닫기
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: const Text('확인', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        } else {
          // ✅ 2~9호선은 바로 혼잡도 예측 화면으로 이동
          Navigator.pushNamed(
            context,
            '/congestion',
            arguments: {
              'line': line,
              'station': station,
              'destination': destination,
              'fastTransfer': fastTransfer,
              'time': time,
              'duration': duration,
              'stationCount': stationCount,
              'iconCodePoint': icon.codePoint,
              'colorValue': color.value,

              // 🔥 시간 전달
              'departureTime': departureTime.format(context),
              'arrivalTime': arrivalTime.format(context),

              // ⭐ 즐겨찾기 여부도 전달
              'isFavorite': isFavorite,
            },
          );

        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          '혼잡도 예측',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }


  Future<void> _selectTime(BuildContext context, bool isDeparture) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isDeparture ? departureTime : arrivalTime,
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
        if (isDeparture) {
          departureTime = picked;
        } else {
          arrivalTime = picked;
        }
      });
    }
  }





  Widget _buildRouteStep({
    required String time,
    required String station,
    required String line,
    required Color color,
    required String duration, // ✅ 이거 추가
    required String stationCount,
    required String destination,
    required String fastTransfer,
    required IconData icon,
    required BuildContext context,
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
                    height: 80, // ✅ 아이콘 사이 거리 설정
                    color: color,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(station, style: const TextStyle(fontSize: 14)),
                    Text(destination, style: const TextStyle(fontSize: 14)),
                    Text(fastTransfer, style: const TextStyle(fontSize: 14)),
                    Text(
                      '${durationText} ($stationCount)', // ✅ 자동 계산된 시간 사용
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ✅ 시간 → 아이콘 왼쪽 정중앙에 배치
        Positioned(
          left: 10,
          top: 14,
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),

        // ✅ 소요 시간 → 아이콘과 아이콘 사이의 정중앙 왼쪽에 배치
        Positioned(
          left: 3,
          top: 60,
          child: Text(
            durationText, // ✅ 여기서도 자동 계산된 시간 사용
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),

        // ✅ 혼잡도 예측 버튼
        Positioned(
          right: 16,
          bottom: 0,
          child: _buildCongestionButton(
            context,
            line: line,
            station: station,
            destination: destination,
            fastTransfer: fastTransfer,
            time: time,
            duration: durationText, // ✅ 계산된 시간 전달
            stationCount: stationCount,
            icon: icon,
            color: color,
          ),
        ),
      ],
    );
  }



// ✅ 환승 정보 위젯 (시간 + 소요 시간 정확히 위치)
  Widget _buildTransferStep({
    required String time,
    required String station,
    required String distance,
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
                  _buildCircularIcon(Icons.directions_walk, Colors.grey),
                  Container(
                    width: 6,
                    height: 50, // ✅ 아이콘 사이 거리 설정
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$station',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(distance,
                        style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ✅ 시간 → 아이콘의 정중앙 왼쪽에 배치
        Positioned(
          left: 10,
          top: 14, // ✅ 정확한 중앙값 설정
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),

        // ✅ 소요 시간 → 아이콘 사이 중앙값에 정확히 배치
        Positioned(
          left: 40, // ✅ 아이콘의 중앙 왼쪽에 고정
          top: 50, // ✅ 두 아이콘 사이의 중앙값 설정 (50의 절반)
          child: const Text(
            '5분',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

// ✅ 도착 정보 위젯 (시간만 왼쪽에 고정)
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
              _buildCircularIcon(Icons.location_on, Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Text('$station',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        // ✅ 시간 → 아이콘의 정중앙 왼쪽에 배치
        Positioned(
          left: 10,
          top: 14,
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

// ✅ 원형 아이콘 생성 함수
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