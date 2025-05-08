import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SubwayTimetableScreen extends StatefulWidget {
  final String lineCode;
  final String lineName;
  final String stationCode;
  final String stationName;

  const SubwayTimetableScreen({
    super.key,
    required this.lineCode,
    required this.lineName,
    required this.stationCode,
    required this.stationName,
  });

  @override
  State<SubwayTimetableScreen> createState() => _SubwayTimetableScreenState();
}

class _SubwayTimetableScreenState extends State<SubwayTimetableScreen> {
  List<dynamic> upTrains = [];
  List<dynamic> downTrains = [];

  String selectedDay = 'WEEKDAY'; // 기본 값 평일
  bool expressOnly = false;

  @override
  void initState() {
    super.initState();
    fetchTimetable();
  }

  Future<void> fetchTimetable() async {
    final url = Uri.parse(
      'http://43.200.50.230/api/v1/stations/${widget.stationCode}/timetable?lineCode=${widget.lineCode}&type=$selectedDay',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final result = data['result'];
      setState(() {
        upTrains = result['up']; // 시청 방향
        downTrains = result['down']; // 남영 방향
      });
    } else {
      print('API 호출 실패: ${response.statusCode}');
    }
  }

  Widget _buildTrainList(List<dynamic> trains) {
    final filtered = expressOnly
        ? trains.where((t) => t['trainType'] == 'EXPRESS').toList()
        : trains;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final train = filtered[index];
        final isExpress = train['trainType'] == 'EXPRESS';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    train['departureTime'] ?? '',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (isExpress)
                    const Padding(
                      padding: EdgeInsets.only(left: 12), // 오른쪽으로 2mm 정도 이동
                      child: Text(
                        '급행',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                '${train['startStationName']} > ${train['endStationName']}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text('${widget.stationName}역 ${widget.lineName}'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 요일 선택 라디오 & 급행 체크
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildDayRadio('평일'),
                  const SizedBox(width: 8),
                  _buildDayRadio('토요일'),
                  const SizedBox(width: 8),
                  _buildDayRadio('공휴일'),
                  const Spacer(),
                  Transform.translate(
                    offset: const Offset(0, -12),
                    child: Row(
                      children: [
                        const Text('급행'),
                        Checkbox(
                          value: expressOnly,
                          onChanged: (val) {
                            setState(() {
                              expressOnly = val ?? false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          downTrains.isNotEmpty && downTrains[0].containsKey('prevStationName')
                              ? downTrains[0]['prevStationName']
                              : '시청 방향',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        _buildTrainList(downTrains),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          upTrains.isNotEmpty && upTrains[0].containsKey('nextStationName')
                              ? upTrains[0]['nextStationName']
                              : '남영 방향',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        _buildTrainList(upTrains),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayRadio(String day) {
    return Row(
      children: [
        Radio<String>(
          value: day.toUpperCase(),
          groupValue: selectedDay,
          onChanged: (value) {
            setState(() {
              selectedDay = value!;
              fetchTimetable();
            });
          },
        ),
        Text(
          day,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
