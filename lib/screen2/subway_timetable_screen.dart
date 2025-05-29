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
  Map<String, List<dynamic>> cachedUpTrains = {};
  Map<String, List<dynamic>> cachedDownTrains = {};
  bool isLoading = true;

  String selectedDay = 'WEEKDAY';
  bool expressOnly = false;

  @override
  void initState() {
    super.initState();

    final weekday = DateTime.now().weekday;
    if (weekday == DateTime.saturday) {
      selectedDay = 'SATURDAY';
    } else if (weekday == DateTime.sunday) {
      selectedDay = 'HOLIDAY';
    } else {
      selectedDay = 'WEEKDAY';
    }
    fetchAllTimetables();
  }
  Future<void> fetchAllTimetables() async {
    final dayTypes = ['WEEKDAY', 'SATURDAY', 'HOLIDAY'];

    for (final day in dayTypes) {
      final url = Uri.parse(
        'http://43.200.50.230/api/v1/stations/${widget.stationCode}/timetable?lineCode=${widget.lineCode}&type=$day',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final result = data['result'];
        final scheduleKey = day == 'WEEKDAY'
            ? 'weekdaySchedule'
            : day == 'SATURDAY'
            ? 'saturdaySchedule'
            : 'holidaySchedule';

        cachedUpTrains[day] = result[scheduleKey]?['up'] ?? [];
        cachedDownTrains[day] = result[scheduleKey]?['down'] ?? [];
      } else {
        print('❌ 요일 $day 실패: ${response.statusCode}');
        cachedUpTrains[day] = [];
        cachedDownTrains[day] = [];
      }
    }

    setState(() {
      isLoading = false;
      upTrains = cachedUpTrains[selectedDay] ?? [];
      downTrains = cachedDownTrains[selectedDay] ?? [];
    });
  }

  Future<void> fetchTimetable() async {
    if (cachedUpTrains.containsKey(selectedDay)) {
      setState(() {
        upTrains = cachedUpTrains[selectedDay]!;
        downTrains = cachedDownTrains[selectedDay]!;
      });
      return;
    }

    final url = Uri.parse(
      'http://43.200.50.230/api/v1/stations/${widget.stationCode}/timetable?lineCode=${widget.lineCode}&type=$selectedDay',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final result = data['result'];
      final scheduleKey = selectedDay == 'WEEKDAY'
          ? 'weekdaySchedule'
          : selectedDay == 'SATURDAY'
          ? 'saturdaySchedule'
          : 'holidaySchedule';

      final up = result[scheduleKey]?['up'] ?? [];
      final down = result[scheduleKey]?['down'] ?? [];

      setState(() {
        upTrains = up;
        downTrains = down;
        cachedUpTrains[selectedDay] = up;
        cachedDownTrains[selectedDay] = down;
      });
    } else {
      print('API 호출 실패: ${response.statusCode}');
    }
  }


  Widget _buildTrainList(List<dynamic> trains) {
    final filtered = expressOnly
        ? trains.where((t) {
      final type = t['trainType'];
      return type == 'EXPRESS' || type == 'RAPID';
    }).toList()
        : trains;



    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final train = filtered[index];
        final trainType = train['trainType'];
        String? label;

        if (trainType == 'EXPRESS') {
          label = '특급';
        } else if (trainType == 'RAPID') {
          label = '급행';
        }

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
                  if (label != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        label,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
      body: Stack(
        children: [
          // ✅ 스크롤 가능한 본문 (열차 시간만)
          Padding(
            padding: const EdgeInsets.only(top: 136), // 전체 상단 고정 영역만큼 여백
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTrainList(upTrains)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTrainList(downTrains)),
                  ],
                ),
              ),
            ),
          ),

          // ✅ 상단 고정 영역 (역 이름 + 필터 + 방향)
          SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ⬆ AppBar 대체
                Padding(
                  padding: const EdgeInsets.fromLTRB(13, 12, 16, 8), // ← 여백 추가
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(32),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.arrow_back, size: 24, color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.stationName} ${widget.lineName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),


                // ⬇ 필터 바
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.white,
                  child: Row(
                    children: [
                      _buildDayRadio('평일', 'WEEKDAY'),
                      const SizedBox(width: 8),
                      _buildDayRadio('토요일', 'SATURDAY'),
                      const SizedBox(width: 8),
                      _buildDayRadio('일요일', 'HOLIDAY'),
                      const Spacer(),
                      Transform.translate(
                        offset: const Offset(0, -8),
                        child: Row(
                          children: [
                            const Text('급행'),
                            Checkbox(
                              value: expressOnly,
                              onChanged: (val) {
                                setState(() {
                                  expressOnly = val ?? false;
                                  upTrains = cachedUpTrains[selectedDay] ?? [];
                                  downTrains = cachedDownTrains[selectedDay] ?? [];
                                });
                              },
                            ),

                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ⬇ 방향 바
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    color: Colors.white,
                    child: Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              downTrains.isNotEmpty && downTrains[0].containsKey('prevStationName')
                                  ? downTrains[0]['prevStationName']
                                  : '시청 방향',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft, // ⬅ 여기 중요
                            child: Text(
                              upTrains.isNotEmpty && upTrains[0].containsKey('nextStationName')
                                  ? upTrains[0]['nextStationName']
                                  : '남영 방향',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    )
                ),

                const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayRadio(String label, String value) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: selectedDay,
          onChanged: (val) {
            setState(() {
              selectedDay = val!;
              fetchTimetable();
            });
          },
        ),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
