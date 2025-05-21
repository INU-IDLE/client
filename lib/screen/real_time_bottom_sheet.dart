import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class RealTimeBottomSheet extends StatefulWidget {
  final Color color;
  final String line;
  final String station;
  final String fastTransfer;
  final IconData icon;
  final String duration;
  final String arrivalStation;
  final String arrivalTime;
  final List<int> sectionDurations;
  final List<Map<String, dynamic>> carsList;
  final List<String> arrivalTimes;

  final String nowTime = DateFormat('HH:mm').format(DateTime.now());


  RealTimeBottomSheet({
    Key? key,
    required this.color,
    required this.line,
    required this.station,
    required this.fastTransfer,
    required this.icon,
    required this.duration,
    required this.arrivalStation,
    required this.arrivalTime,
    required this.sectionDurations,
    required this.carsList,
    required this.arrivalTimes,
  }) : super(key: key);

  @override
  State<RealTimeBottomSheet> createState() => _RealTimeBottomSheetState();
}
class _RealTimeBottomSheetState extends State<RealTimeBottomSheet> {
  late String nowTime;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    nowTime = DateFormat('hh:mm a').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.855,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 상단 타이틀
              Text(
                '실시간 혼잡도 - ${widget.line}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),

              // 출발/도착 시간 박스
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('출발 $nowTime',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    Text('도착 ${_calculateArrivalTimeFromDurationString(widget.duration).format(context)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 노선 정보
              _buildRouteStep(),

              // 도보 정보

              _buildArrivalOrTransferStep(),
              const SizedBox(height: 75),
              _buildCongestionLegend(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteStep() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 60, right: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  _buildCircularIcon(	widget.icon, widget.color),
                  Container(
                    width: 6,
                    height: 300,
                    color: widget.color,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 6.5),
                    Text(
                      widget.line,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.color,
                      ),
                    ),
                    Text(
                      '${widget.station}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    Text(widget.fastTransfer, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 12),
                    _buildCongestionGraph(),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 35,
          top: 170,
          child: Text(
            widget.duration,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        Positioned(
          left: 10,
          top: 6.5,
          child: Text(
            DateFormat('HH:mm').format(DateTime.now()),
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
  String _calculateArrivalTimeFromDurations() {
    final now = DateTime.now();
    final totalMinutes = widget.sectionDurations.fold(0, (sum, value) => sum + value);
    final arrival = now.add(Duration(minutes: totalMinutes));
    return DateFormat('HH:mm').format(arrival);
  }
  TimeOfDay _calculateArrivalTimeFromDurationString(String duration) {
    final now = TimeOfDay.now();
    final nowDateTime = DateTime(0, 1, 1, now.hour, now.minute);

    final regex = RegExp(r'(?:(\d+)시간)?\s*(\d+)분');
    final match = regex.firstMatch(duration);

    int hour = 0;
    int minute = 0;

    if (match != null) {
      if (match.group(1) != null) {
        hour = int.parse(match.group(1)!);
      }
      minute = int.parse(match.group(2)!);
    }

    final totalMinutes = hour * 60 + minute;
    final arrival = nowDateTime.add(Duration(minutes: totalMinutes));

    return TimeOfDay.fromDateTime(arrival);
  }



  String _getNowTimeFormatted24() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getArrivalTimeFromNow(String duration) {
    final now = DateTime.now();
    final durParts = duration.split(RegExp(r'[시간분\s]+')).where((e) => e.isNotEmpty).toList();

    int durHour = durParts.length == 2 ? int.parse(durParts[0]) : 0;
    int durMin = durParts.length == 2 ? int.parse(durParts[1]) : int.parse(durParts[0]);

    final arrival = now.add(Duration(hours: durHour, minutes: durMin));
    final hour = arrival.hour.toString().padLeft(2, '0');
    final minute = arrival.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }


  Widget _buildTransferStep() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 60, right: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  _buildCircularIcon(Icons.location_on, Colors.redAccent),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6.5),
                      child: Text(
                        '${widget.arrivalStation} 하차',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          top: 10,
          child: Text(
            DateFormat('HH:mm').format(
                DateTime(0, 1, 1,
                    _calculateArrivalTimeFromDurationString(widget.duration).hour,
                    _calculateArrivalTimeFromDurationString(widget.duration).minute
                )
            ),
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

  Widget _buildArrivalOrTransferStep() {
    if (widget.line == '1호선') {
      return _buildArrivalStep(
        time: widget.arrivalTime,
        station: '${widget.arrivalStation} 하차',
      );
    } else {
      return _buildTransferStep(); // 고정된 텍스트 '부평역 하차' 등 사용 중
    }
  }

  Widget _buildArrivalStep({
    required String time,
    required String station,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 60, right: 16, top: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 시간 텍스트 위로 올리기
          Positioned(
            left: -50, // 왼쪽으로 조금 이동
            top: -6,   // 위로 올리기 (원하면 -10까지도 가능)
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          // 아이콘과 역명
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCircularIcon(Icons.location_on, Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  station,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildCongestionGraph() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

        children: List.generate(widget.carsList.length, (idx) {
          final cars = widget.carsList[idx];
          final sortedKeys = cars.keys.toList()..sort();
          final seatColors = sortedKeys.map((carKey) {
            final car = cars[carKey];
            return _getColor(car['level']);
          }).toList();
        // arrivalTime (예: '5분 후', '10분 후' 등)
        final label = (widget.arrivalTimes.length > idx) ? widget.arrivalTimes[idx] : '';

        return Padding(
              padding: EdgeInsets.only(bottom: idx == widget.carsList.length - 1 ? 0 : 40), // 간격 넓게!
          child: _buildTrainRow(
          label: label,
          seatColors: seatColors,
          ),
        );
      }).toList(),
    );
  }

  Color _getColor(String level) {
    switch (level) {
      case 'WARNING':
        return const Color(0xFFF70505);
      case 'CROWDED':
        return const Color(0xFFEED906);
      case 'NORMAL':
        return const Color(0xFF52B93E);
      case 'RELAXED':
        return const Color(0xFF4863EC);
      default:
        return Colors.grey.shade300;
    }
  }

  Widget _buildTrainRow({
    required String label,
    required List<Color> seatColors,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxCount = seatColors.length;
          final boxWidth = 22.0;
          final spacing = 2.0;

          final totalWidth = boxCount * boxWidth + (boxCount - 1) * spacing;

          return Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: totalWidth,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    children: [
                      _buildLeftHalfCircle(seatColors.first),
                      ...seatColors.sublist(1, seatColors.length - 1).map(_buildSeatBox).toList(),
                      _buildRightHalfCircle(seatColors.last),
                    ],
                  ),
                  Positioned(
                    right: 20, // 그래프 오른쪽 기준 텍스트 위치
                    top: -22,
                    child: Text(
                      label,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
        borderRadius: const BorderRadius.only(
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
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          bottomLeft: Radius.circular(5),
          topRight: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
    );
  }


  Widget _buildCongestionLegend() {
    return Column(
      children: [
        const Text(
          '혼잡도는 다음과 같이 4단계로 분류했습니다.',
          style: TextStyle(fontSize: 12, color: Colors.black),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: const Color(0xFFF70505)), // 빨강
            const SizedBox(width: 8),
            _LegendDot(color: const Color(0xFFEED906)), // 노랑
            const SizedBox(width: 8),
            _LegendDot(color: const Color(0xFF52B93E)), // 초록
            const SizedBox(width: 8),
            _LegendDot(color: const Color(0xFF4863EC)), // 파랑
          ],
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

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}