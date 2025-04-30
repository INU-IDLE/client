import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // JSON 파일 로드
import '../widgets/station_map_painter.dart'; // CustomPainter
import '../models/station.dart'; // Station 모델
import '../services/station_service.dart'; // StationService

class SubwayMapScreen extends StatefulWidget {
  const SubwayMapScreen({super.key});

  @override
  State<SubwayMapScreen> createState() => _SubwayMapScreenState();
}

class _SubwayMapScreenState extends State<SubwayMapScreen> {
  late StationService _stationService; // 역 서비스
  List<Station> _stations = []; // 역 리스트
  Station? _selectedStation; // 선택된 역

  @override
  void initState() {
    super.initState();
    _stationService = StationService([]); // 초기에는 빈 리스트로 시작
    _loadStations(); // JSON 데이터 로드
  }

  // JSON 파일에서 역 데이터를 로드
  Future<void> _loadStations() async {
    try {
      final String posJson =
      await rootBundle.loadString('assets/images/station_positions.json');
      final String infoJson =
      await rootBundle.loadString('assets/station_info.json');

      final List<dynamic> posList = json.decode(posJson);
      final List<dynamic> infoList = json.decode(infoJson);

      // infoList를 id 기반으로 Map으로 변환하여 빠르게 매칭
      final infoMap = {for (var item in infoList) item['id']: item};

      final List<Station> mergedStations = posList.map((pos) {
        final info = infoMap[pos['id']];
        return Station.fromJson({
          ...pos,
          ...?info, // null일 경우 안전하게 처리
        });
      }).toList();

      setState(() {
        _stations = mergedStations;
        _stationService = StationService(_stations);
      });
    } catch (e) {
      print('역 데이터 로드 오류: $e');
    }
  }

  // 클릭된 위치와 노드 좌표 비교
  void handleTap(Offset position) {
    final tappedStation = _stationService.findStationByTap(position);
    if (tappedStation != null) {
      setState(() {
        _selectedStation = tappedStation;
      });
      print('클릭된 역 ID: ${tappedStation.id}');
      print('역 이름: ${tappedStation.stationNm}');
      print('호선: ${tappedStation.line}');
    } else {
      print('해당 위치에 역이 없습니다: $position');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          GestureDetector(
            onTapDown: (details) => handleTap(details.localPosition),
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(100),
              minScale: 0.3,
              maxScale: 3.0,
              child: Stack(
                children: [
                  // PNG 배경 이미지 렌더링
                  Image.asset(
                    'assets/images/metropolitan.png', // PNG 파일 경로 확인 필요
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  // CustomPainter로 역 표시
                  CustomPaint(
                    size: const Size(4500, 3800), // 지도 크기 설정
                    painter:
                    StationMapPainter(_stations, _selectedStation?.id),
                  ),
                  // 각 역의 위치에 클릭 가능한 Circle Widget 추가
                  ..._stations.map((station) {
                    return Positioned(
                      left: station.cx - station.r, // 중심 맞춤
                      top: station.cy - station.r,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedStation = station;
                          });
                          print('클릭된 역 ID: ${station.id}');
                          print('역 이름: ${station.stationNm}');
                        },
                        child: Container(
                          width: station.r * 2,
                          height: station.r * 2,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            border:
                            Border.all(color: Colors.blueAccent, width: 2),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          if (_selectedStation != null)
            Positioned(
              left: _selectedStation!.cx + 20, // 선택된 역의 좌표 기준으로 위치 설정
              top: _selectedStation!.cy - 20,
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () => print('출발지 선택됨'),
                    child:
                    Text('출발지 (${_selectedStation!.stationNm})'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => print('도착지 선택됨'),
                    child:
                    Text('도착지 (${_selectedStation!.stationNm})'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}