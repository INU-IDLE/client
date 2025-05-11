
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/realtime_train.dart'; // RealTimeTrain 모델 필요
import '../data/line_mapping.dart';
import 'package:flutter/material.dart';
import '../models/station.dart';
import '../widgets/station_component.dart';
import '../data/station_data.dart';

class RealTimeScreen extends StatefulWidget {
  const RealTimeScreen({super.key});

  @override
  State<RealTimeScreen> createState() => _RealTimeScreenState();
}

class _RealTimeScreenState extends State<RealTimeScreen> {
  String selectedLine = '2호선';
  String selectedDirection = '내선';
  final ScrollController _scrollController = ScrollController();
  String? selectedStationId;

  // 노선별 이미지 & 역 필터링
  final Map<String, String> lineAssets = {
    '1호선': 'assets/images/line1.png',
    '2호선': 'assets/images/line2.png',
    '3호선': 'assets/images/line3.png',
    '4호선': 'assets/images/line4.png',
    // 이미지 준비되는 대로 추가할 예정
  };
// 실시간 열차 데이터 상태
  List<RealTimeTrain> _realtimeTrains = [];
  bool _isLoading = false;
  String? _errorMessage;

// API 호출 메서드
  Future<void> _fetchRealTimeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiKey = dotenv.env['SUBWAY_API_KEY'] ?? '';
      if (apiKey.isEmpty) throw Exception('API 키가 설정되지 않았습니다.');

      final lineCode = lineNameToApiCode[selectedLine] ?? "1001";
      final url = 'http://openapi.seoul.go.kr:8088/$apiKey/json/realtimePosition/1/100/$lineCode';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['realtimePosition'] == null || data['realtimePosition']['row'] == null) {
          setState(() {
            _errorMessage = '실시간 데이터가 없습니다.';
            _realtimeTrains = [];
          });
          return;
        }
        final rows = data['realtimePosition']['row'] as List;
        setState(() {
          _realtimeTrains = rows.map((e) => RealTimeTrain.fromJson(e)).toList();
        });
      } else {
        throw Exception('API 요청 실패: ${response.statusCode}');
      }

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  @override
  void initState() {
    super.initState();
    _fetchRealTimeData();
  }

  List<Station> get _currentLineStations => stationData
      .where((s) => s.line == lineNameToApiCode[selectedLine])
      .toList();

  void _handleLineSelect(String line) {
    setState(() {
      selectedLine = line;
      selectedStationId = null;
      _scrollToCenter();
    });
    _fetchRealTimeData();
  }

  void _scrollToCenter() {
    final index = lineAssets.keys.toList().indexOf(selectedLine);
    final offset = index * 120.0 - MediaQuery.of(context).size.width / 2 + 60;
    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildRealTimeTrains() {
    return CustomPaint(
      painter: RealTimeTrainPainter(
        trains: _realtimeTrains,
        stations: _currentLineStations,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TransformationController _transformationController = TransformationController();
    return Padding(
      padding: const EdgeInsets.only(top: 50),
      child: Column(
        children: [
          // 노선 스크롤바
          SizedBox(
            height: 70,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: lineAssets.length,
              itemBuilder: (context, index) {
                final line = lineAssets.keys.elementAt(index);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: ChoiceChip(
                    label: Text(line, style: const TextStyle(fontSize: 16)),
                    selected: line == selectedLine,
                    selectedColor: Colors.blue,
                    labelStyle: TextStyle(
                      color: line == selectedLine ? Colors.white : Colors.black,
                    ),
                    onSelected: (_) => _handleLineSelect(line),
                  ),
                );
              },
            ),
          ),
          // 상/하행 선택
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ToggleButtons(
              isSelected: ['상행', '하행'].map((e) => e == selectedDirection).toList(),
              onPressed: (index) => setState(() =>
              selectedDirection = ['상행', '하행'][index]),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('상행', style: TextStyle(fontSize: 16)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('하행', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
          // 지도 & 역 표시
          Expanded(
            child: InteractiveViewer(
              minScale: 0.3,
              maxScale: 2.0,
              boundaryMargin: const EdgeInsets.all(200),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    lineAssets[selectedLine]!,
                    width: 4500,
                    height: 3800,
                    fit: BoxFit.contain,
                  ),
                  StationComponent(
                    stations: _currentLineStations,
                    selectedId: selectedStationId,
                    onStationTap: (id) => setState(() {
                      selectedStationId = id;
                      final station = _currentLineStations.firstWhere(
                            (s) => s.id == id,
                        orElse: () => Station(
                            id: '',
                            cx: 0,
                            cy: 0,
                            r: 0,
                            stationNm: '',
                            line: ''
                        ),
                      );
                      if (station.id.isNotEmpty) {
                        print('${station.stationNm} 선택됨');
                      }
                    }),
                      transformationController: _transformationController,
                  ),
                  if (!_isLoading && _errorMessage == null) _buildRealTimeTrains(),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator()),
                  if (_errorMessage != null)
                    Center(child: Text(_errorMessage!)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RealTimeTrainPainter extends CustomPainter {
  final List<RealTimeTrain> trains;
  final List<Station> stations;

  RealTimeTrainPainter({required this.trains, required this.stations});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    for (final train in trains) {
      final station = stations.firstWhere(
            (s) => _normalizeStationName(s.stationNm) == _normalizeStationName(train.currentStation),
        orElse: () => Station(
            id: '',
            cx: 0,
            cy: 0,
            r: 0,
            stationNm: '',
            line: ''
        ),
      );

      if (station.id.isNotEmpty) {
        canvas.drawCircle(
          Offset(station.cx, station.cy),
          15,
          paint,
        );
      }
    }
  }

  String _normalizeStationName(String name) {
    return name.replaceAll('역', '').trim();
  }

  @override
  bool shouldRepaint(covariant RealTimeTrainPainter oldDelegate) {
    return oldDelegate.trains != trains;
  }
}