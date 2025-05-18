  import 'dart:convert';
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart'; // For loading JSON files
  import 'package:rushcutter/models/station.dart';
  import 'dart:math';
  import 'dart:ui';

  /*
  station_service.dart
  │
  ├─ class StationService {
  │    ├─ searchStations()     // 이름 포함 검색
  │    ├─ findByName()         // 정확 이름 검색
  │    ├─ findStationByTap()   // 좌표 기준 검색
  │    └─ getStationByFrCode() // frCode 기준 검색
  │
  └─ Future<List<Station>> loadStations()

  _subway_map_screen.dart
  │
  ├─ initState()
  │    └─ loadAndInitStations() ← 외부 loadStations() 호출
  │
  ├─ _stationService ← StationService 인스턴스
  └─ _stations ← 역 전체 리스트

   */


  // 이름 일치하는 역 찾는 service 의미
  class StationService {
    Future<String?> getFrCodeByStationName(String stationName) async {
      final jsonString = await rootBundle.loadString('assets/station_info.json');
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      final List<dynamic> stationList = jsonMap['DATA'];

      final trimmedName = stationName.replaceAll('역', '');

      final match = stationList.firstWhere(
              (station) =>
          station['station_nm'].toString().trim().replaceAll('역', '') ==
              stationName.toString().trim().replaceAll('역', '')

      );

      return match?['fr_code']?.toString();
    }

    final List<Station> _stations;

    StationService(this._stations);

    static Future<List<Station>> loadStations() async {
      final String mergedJson = await rootBundle.loadString(
          'assets/images/station_positions_merged.json');
      final List<dynamic> dataList = json.decode(mergedJson);

      return dataList.map<Station>((data) {
        return Station(
          id: data['id'].toString(),
          cx: (data['cx'] as num).toDouble(),
          cy: (data['cy'] as num).toDouble(),
          r: (data['r'] as num).toDouble(),
          stationNm: data['station_nm'] ?? 'Unknown',
          line: data['line_num'] ?? 'Unknown',
        );
      }).toList();
    }


    // 예: "서울" → ["서울역", "서울대입구", ...]
    List<Station> searchStations(String query) {
      return _stations.where((station) =>
      station.stationNm?.contains(query) ?? false).toList();
    }

    // 이름 정확히 일치하는 역 찾기
    Station? findByName(String name) {
    try {
      return _stations.firstWhere((station) => station.stationNm == name);
    } catch (_) {
      return null;
    }
    }

    // 클릭 위치와 가까운 역 찾기
    Station? findStationByTap(Offset tapPosition, {double threshold = 25}) {
      for (final station in _stations) {
        if (station.cx != null && station.cy != null) {
          final distance = sqrt(
            pow(tapPosition.dx - station.cx!, 2) +
                pow(tapPosition.dy - station.cy!, 2),
          );
          if (distance <= threshold) {
            return station;
          }
        }
      }
      return null;
    }

    // frCode 기준 검색
    Station? getStationByFrCode(String frCode) {
      try {
        return _stations.firstWhere((station) => station.id == frCode);
      } catch (_) {
        return null;
      }
    }
  }

  class SubwayMapScreen extends StatefulWidget {
    const SubwayMapScreen({super.key});

    @override
    State<SubwayMapScreen> createState() => _SubwayMapScreenState();
  }


  class _SubwayMapScreenState extends State<SubwayMapScreen> {
    late StationService _stationService;
    List<Station> _stations = [];
    Station? _selectedStation;
    Station? _departureStation;
    Station? _arrivalStation;

    final TransformationController _transformationController = TransformationController();

    // Json에서 station 로드하고 info와 매핑
    static Future<List<Station>> loadStations() async {
      final String positionJson = await rootBundle.loadString(
          'assets/images/station_positions.json');
      final String infoJson = await rootBundle.loadString(
          'assets/station_info.json');

      final List<dynamic> posList = json.decode(positionJson);
      final List<dynamic> infoList = json.decode(infoJson);

      // fr_code 기준으로 info 데이터 매핑
      final Map<String, dynamic> infoMap = {
        for (final info in infoList) info['fr_code'].toString(): info,
      };
      return posList.map<Station>((pos) {
        final id = pos['id'].toString();
        final info = infoMap[id];

        return Station(
          id: id,
          cx: (pos['cx'] as num).toDouble(),
          cy: (pos['cy'] as num).toDouble(),
          r: (pos['r'] as num).toDouble(),
          stationNm: info?['station_nm'] ?? 'Unknown',
          line: info?['line_num'] ?? 'Unknown',
        );
      }).toList();
    }

    Future<void> loadAndInitStations() async {
      final stations = await loadStations(); // 외부 함수 사용
      setState(() {
        _stations = stations;
        _stationService = StationService(stations);
      });
    }

    @override
    void initState() {
      super.initState();
      loadAndInitStations(); // JSON 데이터 로드
    }

    // 클릭된 위치와 노드 좌표 비교
    void handleTap(Offset localPosition) {
      final Matrix4 matrix = _transformationController.value;
      final inverseMatrix = Matrix4.inverted(matrix);
      final transformed = MatrixUtils.transformPoint(inverseMatrix, localPosition); // 확대/이동 보정 좌표

      final tapped = _stationService.findStationByTap(transformed);
      if (tapped != null) {
        setState(() {
          _selectedStation = tapped;
        });
        print('✅ 클릭된 역 ID: ${tapped.id}');
        print('✅ 역 이름: ${tapped.stationNm}');
      } else {
        print('❌ 역을 찾을 수 없음: $transformed');
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // SVG를 터치 가능한 상태로 표시 + 확대/축소 가능
            GestureDetector(
              onTapDown: (details) => handleTap(details.localPosition),
              child: InteractiveViewer(
                transformationController: _transformationController, // 중요
                child: Image.asset(
                  'assets/images/metropolitan.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // 선택된 역이 있을 때만 정보 버튼 표시
            if (_selectedStation != null &&
                _selectedStation!.cx != null &&
                _selectedStation!.cy != null)
              Positioned(
                // 버튼 위치는 SVG 내 좌표 기준으로 설정
                left: _selectedStation!.cx! - 50,
                top: _selectedStation!.cy! - 90,
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _departureStation = _selectedStation;
                        });
                      },
                      child: Text('출발지 (${_selectedStation!.stationNm})'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _arrivalStation = _selectedStation;
                        });
                      },
                      child: Text('도착지 (${_selectedStation!.stationNm})'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }
  }