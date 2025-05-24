import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rushcutter/screen/bottom_category_bar.dart';
import 'package:rushcutter/screen/real_time_screen.dart';
import 'package:rushcutter/screen/saved_routes_screen.dart';
import 'package:rushcutter/screen/news_screen.dart';
import 'package:rushcutter/screen/my_page_screen.dart';
import 'package:rushcutter/screen/search_screen.dart';
import 'package:rushcutter/widgets/station_component.dart';
import 'package:rushcutter/models/station.dart';
import 'package:rushcutter/screen/subway_map_screen.dart';
import 'package:rushcutter/data/station_data.dart';
import 'package:rushcutter/screen2/subway_timetable_screen.dart';
import 'package:rushcutter/screen/real_time_screen.dart';
import 'package:rushcutter/data/line_mapping.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  String? selectedStationId;
  Station? selectedStation; // 클릭된 역 객체
  String selectedCategory = 'HOME'; // 선택된 카테고리
  String? departureStation; // 출발역
  String? arrivalStation; // 도착역
  String? searchQuery; // 넘어가는 검색 값
  Offset? selectedStationPosition;
  bool showButtons = false; // 버튼 표시 상태
  Station? _lastStationForButton; // 상태변수 (위치 기억하려고)

  final TransformationController _transformationController =
  TransformationController(); // transformation 추가

  @override
  void initState() {
    super.initState();
    _transformationController.value = Matrix4.identity()
      ..scale(1.0);
  }


  void onCategorySelected(String category) {
    setState(() {
      selectedCategory = category;
    });
  }

  // 검색 결과를 처리하는 메서드
  void _handleSearchResult(dynamic result, bool isSelectingDeparture) {
    if (result == null || result['id'] == null) return;

    final station = stationData.firstWhere(
          (s) => s.id == result['id'],
      orElse: () =>
          Station(
              id: '',
              cx: 0,
              cy: 0,
              r: 0,
              stationNm: '',
              line: ''
          ),
    );

    if (station.id.isNotEmpty) {
      setState(() {
        selectedStationId = station.id;
        selectedStation = station;
        _moveToViewPoint(station.cx, station.cy);
        // 즉시 버튼 표시를 위한 추가 처리
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            if (isSelectingDeparture) {
              departureStation = station.stationNm;
            } else {
              arrivalStation = station.stationNm;
            }
          });
        });
      });
    }
  }

  // 특정 위치로 View Point 이동
  void _moveToViewPoint(double cx, double cy) {
    final double scale = 1.3;
    final Size screenSize = MediaQuery
        .of(context)
        .size;
    _transformationController.value = Matrix4.identity()
      ..translate(-cx * scale + screenSize.width / 2,
          -cy * scale + screenSize.height / 2)
      ..scale(scale);
  }


  // 역 클릭 처리, 바로 이동 X, 애니메이션 재생
  void _handleStationTap(String? id) {
    if (id == null) {
      setState(() {
        selectedStation = null;
        selectedStationId = null;
        showButtons = false;
      });
      return;
    }
    final found = stationData.firstWhere(
          (s) => s.id == id,
      orElse: () =>
          Station(id: '',
              cx: 0,
              cy: 0,
              r: 0,
              stationNm: '',
              line: ''),
    );
    if (found.id.isNotEmpty) {
      // 역이 바뀔 때 애니메이션 자연스럽게 재생
      if (selectedStationId != id) {
        setState(() {
          showButtons = false;
        });
        Future.delayed(const Duration(milliseconds: 200), () {
          setState(() {
            selectedStationId = id;
            selectedStation = found;
            _lastStationForButton = found;
            showButtons = true;
          });
        });
      }
    }
  }
  void _hideButtons() {
    if (!showButtons) return; // 이미 숨김 상태면 무시
    setState(() {
      showButtons = false;
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      // 애니메이션이 끝난 뒤에만 selectedStation을 null로!
      if (!showButtons) {
        setState(() {
          selectedStation = null;
          selectedStationId = null;
        });
      }
    });
  }


  // 출발지/도착지 버튼을 누르면 해당 값 입력
  void _onSelectDeparture() async {
    // if (selectedStation == null || selectedStation!.id.isEmpty) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SubwayMapScreen(
              isSelectingDeparture: true,
              selectedStation: selectedStation, // ★ 현재 선택된 역 전달
              initialTransformation: _transformationController.value,
              searchQuery: selectedStation!.stationNm,
            ),
      ),
    );

    setState(() {
      showButtons = false;
    });


    if (result != null && result is String) {
      setState(() {
        departureStation = result;
      });
    }
    Future.delayed(const Duration(milliseconds: 350), () {
      setState(() {
        selectedStation = null;
        selectedStationId = null;
      });
    });
  }

  void _onSelectArrival() async {
    if (selectedStation == null || selectedStation!.id.isEmpty) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SubwayMapScreen(
              initialTransformation: _transformationController.value,
              isSelectingDeparture: false,
              searchQuery: selectedStation!.stationNm,
              selectedStation: selectedStation,

            ),
      ),
    );
    setState(() {
      showButtons = false;
    });
    if (result != null && result is String) {
      setState(() {
        arrivalStation = result;
      });
    }

    setState(() {
      selectedStation = null;
      selectedStationId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery
        .of(context)
        .padding
        .top;

    Widget currentScreen;

    switch (selectedCategory) {
      case 'HOME':
        currentScreen = _buildHomeContent();
        break;
      case '시간표':
        currentScreen = const RealTimeScreen();
        break;
      case '저장':
        currentScreen = const SavedRoutesScreen();
        break;
      case '소식':
        currentScreen = const NewsScreen();
        break;
      case 'MY':
        currentScreen = const MyPageScreen();
        break;
      default:
        currentScreen = _buildHomeContent();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
            children: [
            // 검색창
            Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10),
              ],
            ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 검색창
                    Expanded(
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7E7E7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  // 검색창 클릭 시 SearchScreen으로 이동
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                      const SearchScreen(
                                        isSelectingDeparture: true, // 기본값 설정
                                      ),
                                    ),
                                  );
                                  // 검색 결과 처리
                                  _handleSearchResult(result, true);
                                },
                                child: Text(
                                  departureStation ?? '지하철 역 검색',
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 알림 버튼
                    GestureDetector(
                      onTap: () {
                        print('알림 클릭');
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                              Icons.notifications, size: 30,
                              color: Colors.black),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '99+',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ),
          Expanded(
            child: currentScreen,
          ),
          ],
        ),
      ),

    );
  }
  


  Widget _buildHomeContent() {
    final Station? buttonStation = selectedStation ?? _lastStationForButton;

    return Stack(
        children: [
          Positioned.fill(child: Container(color: Colors.white)),
          Positioned.fill(
            child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.3,
        maxScale: 2.0,
        boundaryMargin: const EdgeInsets.all(500),
        constrained: false,
        child: SizedBox(
          width: 4500,
          height: 3800,
          child: Stack(
            children: [
             Image.asset(
                'assets/images/metropolitan.png',
                width: 4500,
                height: 3800,
                fit: BoxFit.cover,

              ),
              StationComponent(
                stations: stationData,
                selectedId: selectedStationId,
                onStationTap: _handleStationTap,
                  transformationController: _transformationController
              ),
              if (buttonStation != null && buttonStation.id.isNotEmpty)
                Positioned(
                  // left: (buttonStation.cx) - 40,
                  // top: (buttonStation.cy) - 115,
                  left: (buttonStation.cx) - 80,
                  top: (buttonStation.cy) - 90,
                  child: AnimatedSlide(
                    offset: (showButtons)
                        ? Offset.zero
                        : const Offset(0, 0.2),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOutCubic,
                    child: AnimatedOpacity(
                      opacity: showButtons ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOutCubic,
                      onEnd: () {
                        if (!showButtons) {
                          setState(() {
                            selectedStation = null;
                            selectedStationId = null;
                          });
                        }
                      },
                      child: IgnorePointer(
                        ignoring: !showButtons,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [/*
                            ElevatedButton(
                              onPressed: _onSelectDeparture,
                              child: const Text("출발지"),
                              style: ElevatedButton.styleFrom(
                                shape: const StadiumBorder(),
                                elevation: 4,
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shadowColor: Colors.black26,
                              ),
                            ),*/
                        /*
                        const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _onSelectArrival,
                              child: const Text("도착지"),
                              style: ElevatedButton.styleFrom(
                                shape: const StadiumBorder(),
                                elevation: 4,
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shadowColor: Colors.black26,
                              ),
                            ),

                          ],
                        ),*/

// 출발지 버튼
                            _CircleIconButton(
                              icon: Icons.arrow_upward,
                              label: '출발',
                              onTap: _onSelectDeparture,
                            ),
                            const SizedBox(width: 8),
                            // 도착지 버튼
                            _CircleIconButton(
                            icon: Icons.arrow_downward,
                            label: '도착',
                            onTap: _onSelectArrival,
                            ),
                            const SizedBox(width: 8),
                            // Info 버튼
                            // ✅ Info 버튼
                            _CircleIconButton(
                              icon: Icons.info_outline,
                              label: 'Info',
                              onTap: () async {
                                if (buttonStation == null) return;

                                // ✅ 숫자일 경우 2자리로 보정 ('1' -> '01호선')
                                String normalizedLineNum = buttonStation.line;

                                if (RegExp(r'^\d$').hasMatch(normalizedLineNum)) {
                                  normalizedLineNum = '0$normalizedLineNum호선';
                                } else if (RegExp(r'^\d{2}$').hasMatch(normalizedLineNum)) {
                                  normalizedLineNum = '$normalizedLineNum호선';
                                }

                                // 숫자일 경우 앞에 '0' 붙이기
                                if (RegExp(r'^\d$').hasMatch(normalizedLineNum)) {
                                  normalizedLineNum = '0$normalizedLineNum호선';
                                } else if (RegExp(r'^\d{2}$').hasMatch(normalizedLineNum)) {
                                  normalizedLineNum = '$normalizedLineNum호선';
                                }

                                final matchedLine = getMatchedLineInfo(buttonStation.line);

                                final jsonStr = await rootBundle.loadString('assets/station_info.json');
                                final Map<String, dynamic> json = jsonDecode(jsonStr);
                                final List<dynamic> data = json['DATA'];


                                final match = data.firstWhere(
                                      (e) =>
                                  e['station_nm'] == buttonStation.stationNm &&
                                      e['line_num'] == lineNumToName.entries
                                          .firstWhere((entry) => entry.value == matchedLine.name,
                                          orElse: () => const MapEntry('', ''))
                                          .key,
                                  orElse: () => null,
                                );


                                final frCode = match != null ? match['fr_code'] : null;

                                if (frCode == null) {
                                  print('❌ fr_code 못 찾음: ${buttonStation.stationNm}, ${matchedLine.lineNum}');
                                  return;
                                }

                                print('[INFO 버튼 클릭]');
                                print('역 이름: ${buttonStation.stationNm}');
                                print('역 코드: ${buttonStation.id}');
                                print('lineCode (API용): ${matchedLine.lineCode}');
                                print('lineName (UI표시용): ${matchedLine.name}');

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SubwayTimetableScreen(
                                      lineCode: matchedLine.lineCode,
                                      lineName: matchedLine.name,
                                      stationCode: buttonStation.id,
                                      stationName: buttonStation.stationNm,
                                    ),
                                  ),
                                );
                              },
                            ),

                          ],
    ),


                      ),
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    ),
        ]
          );
  }
}
String getLineNameForTimetable(String line) {
  // 그대로 쓰는 노선 (호선/선 붙이지 않음)
  const keepAsIs = [
    '공항철도', '인천1호선', '인천2호선', 'GTX-A', '에버라인', '김포골드'
  ];

  // "선"을 붙여야 하는 노선
  const addSeon = [
    '서해', '의정부', '경의중앙', '신분당', '경강', '우이신설', '경춘', '신림', '수인분당'
  ];

  // 1~9는 "호선" 붙이기
  if (RegExp(r'^[1-9]$').hasMatch(line)) {
    return '$line호선';
  }
  // 그대로 쓰는 노선
  if (keepAsIs.contains(line)) {
    return line;
  }
  // "선" 붙이기
  if (addSeon.contains(line)) {
    return '$line선';
  }
  // 혹시나 위에 안 걸리면 그대로
  return line;
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 2, // 그림자 아주 연하게
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white, // ✅ 완전히 흰 배경
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black, // ✅ 검은색 테두리
              width: 1.2,
            ),

          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.black, size: 18),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
