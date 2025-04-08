import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class RealTimeBottomSheet extends StatefulWidget {
  final Color color;
  final String line;
  final String station;
  final String fastTransfer;
  final IconData icon;
  final String duration;

  final String nowTime = DateFormat('HH:mm').format(DateTime.now());


  RealTimeBottomSheet({
    Key? key,
    required this.color,
    required this.line,
    required this.station,
    required this.fastTransfer,
    required this.icon,
    required this.duration,
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
    nowTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
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
                  margin: const EdgeInsets.only(top: 12, bottom: 24), // ⬅️ 여유 공간 줘서 전체 내려줌
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
                    Text('도착 ${_getArrivalTimeFrom(nowTime, widget.duration)}',
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
                    Text(
                      widget.line,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.color,
                      ),
                    ),
                    Text(widget.station, style: const TextStyle(fontSize: 14)),
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
          left: 10,
          top: 14,
          child: Text(
            nowTime,
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

  String _getArrivalTimeFrom(String time, String duration) {
    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final baseTime = DateTime(0, 1, 1, hour, minute);

    final durParts = duration.split(RegExp(r'[시간분\s]+')).where((e) => e.isNotEmpty).toList();
    final durHour = durParts.length == 2 ? int.parse(durParts[0]) : 0;
    final durMin = durParts.length == 2 ? int.parse(durParts[1]) : int.parse(durParts[0]);

    final resultTime = baseTime.add(Duration(hours: durHour, minutes: durMin));
    return '${resultTime.hour.toString().padLeft(2, '0')}:${resultTime.minute.toString().padLeft(2, '0')}';
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
                  _buildCircularIcon(Icons.directions_walk, Colors.grey),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '부평역 하차',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '도보 316m',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Positioned(
          left: 10,
          top: 14,
          child: Text(
            '11:46',
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
  Widget _buildArrivalOrTransferStep() {
    if (widget.line == '1호선') {
      return _buildArrivalStep(
        time: '12:13',
        station: '구일역 하차',
      );
    } else {
      return _buildTransferStep();
    }
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
              _buildCircularIcon(Icons.location_on, Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  station,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 10,
          top: 14,
          child: Text(
            _getArrivalTimeFromNow(widget.duration),
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
                    .map(_buildSeatBox)
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
          children: const [
            _LegendDot(color: Color(0xFFFB3030)),
            SizedBox(width: 8),
            _LegendDot(color: Color(0xFFFFE619)),
            SizedBox(width: 8),
            _LegendDot(color: Color(0xFF51E817)),
            SizedBox(width: 8),
            _LegendDot(color: Color(0xFF2E2FFB)),
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