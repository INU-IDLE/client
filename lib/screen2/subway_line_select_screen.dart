import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/line_mapping.dart';
import 'station_select_screen.dart';

class SubwayLineSelectScreen extends StatefulWidget {
  const SubwayLineSelectScreen({super.key});

  @override
  State<SubwayLineSelectScreen> createState() => _SubwayLineSelectScreenState();
}

class _SubwayLineSelectScreenState extends State<SubwayLineSelectScreen> {
  List<Map<String, dynamic>> lines = [];

  @override
  void initState() {
    super.initState();
    loadLineList();
  }

  Future<void> loadLineList() async {
    final jsonString = await rootBundle.loadString('assets/station_info.json');
    final json = jsonDecode(jsonString); // 전체 JSON 파싱
    final List<dynamic> data = json['DATA']; // 'DATA' 키 접근

    final Map<String, List<dynamic>> grouped = {};
    for (final station in data) {
      final line = station['line_num'] ?? '기타';
      grouped.putIfAbsent(line, () => []).add(station);
    }

    setState(() {
      lines = grouped.keys.map((lineNum) {
        final matched = subwayLines.firstWhere(
              (m) => m.lineNum == lineNum,
          orElse: () => LineInfo(
            lineNum: lineNum,
            lineCode: 'UNKNOWN',
            name: lineNumToName[lineNum] ?? lineNum,
            color: Colors.grey,
          ),
        );

        return {
          'line_num': matched.lineNum,    // JSON의 line_num (ex: '01호선')
          'line_code': matched.lineCode,  // API 호출용
          'name': matched.name,           // 사용자에게 보여줄 이름
          'color': matched.color,
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('노선 선택')),
      backgroundColor: Colors.white,
      body: lines.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: lines.length,
        itemBuilder: (_, i) {
          final line = lines[i];
          return ListTile(
            leading: CircleAvatar(
              radius: 5,
              backgroundColor: line['color'],
            ),
            title: Text(line['name']),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StationSelectScreen(
                    line: line['line_num'],
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
