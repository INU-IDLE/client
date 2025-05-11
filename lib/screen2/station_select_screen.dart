import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../data/line_mapping.dart';
import '../screen2/subway_timetable_screen.dart';



class StationSelectScreen extends StatefulWidget {
  final String line; // line_num 값 (ex: '01호선')

  const StationSelectScreen({super.key, required this.line});

  @override
  State<StationSelectScreen> createState() => _StationSelectScreenState();
}

class _StationSelectScreenState extends State<StationSelectScreen> {
  List<dynamic> stations = [];
  String? lineName;
  String? lineCode;

  @override
  void initState() {
    super.initState();

    final matched = subwayLines.firstWhere(
          (m) => m.lineNum == widget.line,
      orElse: () => LineInfo(
        lineNum: widget.line,
        lineCode: 'UNKNOWN',
        name: widget.line,
        color: Colors.grey,
      ),
    );

    lineName = matched.name;
    lineCode = matched.lineCode;

    loadStationData();
  }

  Future<void> loadStationData() async {
    final jsonString = await rootBundle.loadString('assets/station_info.json');
    final json = jsonDecode(jsonString);
    final List<dynamic> data = json['DATA'];

    setState(() {
      stations = data.where((station) => station['line_num'] == widget.line).toList();
    });
  }


  @override
  Widget build(BuildContext context) {
    if (lineName == null || lineCode == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('로딩 중...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          ('$lineName 역 선택'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
      ),
      body: ListView.builder(
        itemCount: stations.length,
        itemBuilder: (context, index) {
          final station = stations[index];
          return ListTile(
            title: Text(
              station['station_nm'],
              style: const TextStyle(fontSize: 16),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubwayTimetableScreen(
                    lineName: lineName!,
                    lineCode: lineCode!,
                    stationName: station['station_nm'],
                    stationCode: station['fr_code'],
                  ),
                ),
              );
            },
          );
        },
      ),

    );
  }
}
