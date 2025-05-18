import 'package:flutter/material.dart';

class LineInfo {
  final String lineNum;  // JSON의 line_num (ex: '01호선')
  final String lineCode; // API용 코드 (ex: '1')
  final String name;     // 실제 노출용 이름 (ex: '1호선')
  final Color color;

  const LineInfo({
    required this.lineNum,
    required this.lineCode,
    required this.name,
    required this.color,
  });
}

const List<LineInfo> subwayLines = [
  LineInfo(lineNum: '01호선', lineCode: '1', name: '1호선', color: Color(0xFF0052A4)),
  LineInfo(lineNum: '02호선', lineCode: '2', name: '2호선', color: Color(0xFF00A84D)),
  LineInfo(lineNum: '03호선', lineCode: '3', name: '3호선', color: Color(0xFFEF7C1C)),
  LineInfo(lineNum: '04호선', lineCode: '4', name: '4호선', color: Color(0xFF00A4E3)),
  LineInfo(lineNum: '05호선', lineCode: '5', name: '5호선', color: Color(0xFF996CAC)),
  LineInfo(lineNum: '06호선', lineCode: '6', name: '6호선', color: Color(0xFFCD7C2F)),
  LineInfo(lineNum: '07호선', lineCode: '7', name: '7호선', color: Color(0xFF747F00)),
  LineInfo(lineNum: '08호선', lineCode: '8', name: '8호선', color: Color(0xFFE6186C)),
  LineInfo(lineNum: '09호선', lineCode: '9', name: '9호선', color: Color(0xFFBDB092)),
  LineInfo(lineNum: '경의선', lineCode: 'K4', name: '경의중앙선', color: Color(0xFF77C4A3)),
  LineInfo(lineNum: '경춘선', lineCode: 'K2', name: '경춘선', color: Color(0xFF178C72)),
  LineInfo(lineNum: '수인분당선', lineCode: 'K1', name: '수인·분당선', color: Color(0xFFFABD00)),
  LineInfo(lineNum: '신분당선', lineCode: 'D1', name: '신분당선', color: Color(0xFFD31145)),
  LineInfo(lineNum: '공항철도', lineCode: 'A1', name: '공항철도', color: Color(0xFF0090D2)),
  LineInfo(lineNum: '서해선', lineCode: 'WS', name: '서해선', color: Color(0xFF8FC31F)),
  LineInfo(lineNum: '인천선', lineCode: 'I1', name: '인천1호선', color: Color(0xFF79A0D4)),
  LineInfo(lineNum: '인천2호선', lineCode: 'I2', name: '인천2호선', color: Color(0xFFF5A251)),
  LineInfo(lineNum: '용인경전철', lineCode: 'E1', name: '에버라인(용인)', color: Color(0xFF56AD2D)),
  LineInfo(lineNum: '의정부경전철', lineCode: 'U1', name: '의정부경전철', color: Color(0xFFFD8100)),
  LineInfo(lineNum: '우이신설경전철', lineCode: 'UI', name: '우이신설경전철', color: Color(0xFFB7C450)),
  LineInfo(lineNum: '김포도시철도', lineCode: 'G1', name: '김포골드라인', color: Color(0xFFAD8605)),
  LineInfo(lineNum: '신림선', lineCode: 'L1', name: '신림선', color: Color(0xFF000000)),
  LineInfo(lineNum: '경강선', lineCode: 'K5', name: '경강선', color: Color(0xFF000000)),
  LineInfo(lineNum: 'GTX-A', lineCode: 'A', name: 'GTX-A', color: Colors.black),
];

const Map<String, String> lineNumToName = {
  '01호선': '1호선',
  '02호선': '2호선',
  '03호선': '3호선',
  '04호선': '4호선',
  '05호선': '5호선',
  '06호선': '6호선',
  '07호선': '7호선',
  '08호선': '8호선',
  '09호선': '9호선',
  '경의선': '경의중앙선',
  '경춘선': '경춘선',
  '수인분당선': '수인·분당선',
  '신분당선': '신분당선',
  '공항철도': '공항철도',
  '서해선': '서해선',
  '인천선': '인천1호선',
  '인천2호선': '인천2호선',
  '용인경전철': '에버라인(용인)',
  '의정부경전철': '의정부경전철',
  '우이신설경전철': '우이신설경전철',
  '김포도시철도': '김포골드라인',
  '신림선': '신림선',
  '경강선': '경강선',
  'GTX-A': 'GTX-A',
};
