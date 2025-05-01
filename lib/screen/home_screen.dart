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
      setState(() {
        selectedStationId = station.id; // ★ 추가: 선택 상태 동기화
        selectedStation = station;       // ★ 추가
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

  // 역 클릭 처리 (이제는 바로 이동하지 않고, selectedStation만 세팅)
  void _handleStationTap(String? id) {
    final found = stationData.firstWhere(
          (s) => s.id == id,
      orElse: () =>
          Station(
            id: '',
            cx: 0,
            cy: 0,
            r: 0,
            stationNm: '',
            line: '',
          ),
    );
    setState(() {
      selectedStationId = id;
      selectedStation = found.id.isNotEmpty ? found : null;
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
    if (result != null && result is String) {
      setState(() {
        departureStation = result;
      });
    }

    setState(() {
      selectedStation = null;
      selectedStationId = null;
    });
  }

  void _onSelectArrival() async {
    if (selectedStation == null || selectedStation!.id.isEmpty) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SubwayMapScreen(
              initialTransformation: _transformationController.value, // 추가
              isSelectingDeparture: false,
              searchQuery: selectedStation!.stationNm,
              selectedStation: selectedStation, // ★ 현재 선택된 역 전달

            ),
      ),
    );
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
      case '실시간':
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
      body: Stack(
        children: [
          Positioned.fill(child: currentScreen),
          // 상단 검색창 및 알림 버튼
          if (selectedCategory == 'HOME' || selectedCategory == '실시간')
          Positioned(
            top: statusBarHeight, // 상태바 바로 아래부터 시작
            left: 0,
            right: 0,
            child: Container(
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
                            Icons.notifications, size: 30, color: Colors.black),
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
          ),
        ],
      ),
      bottomNavigationBar: BottomCategoryBar(
        selectedCategory: selectedCategory,
        onCategorySelected: onCategorySelected,
      ),
    );
  }

  Widget _buildHomeContent() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // 빈 공간 클릭 감지를 위해 필수!
      onTap: () {
        // 빈 공간 클릭 시 버튼 숨김
        setState(() {
          selectedStation = null;
          selectedStationId = null;
        });
      },
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.3,
        maxScale: 1.0,
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
              ),
              if (selectedStation != null && selectedStation!.id.isNotEmpty)
                Positioned(
                  left: selectedStation!.cx,
                  top: selectedStation!.cy - 80,
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: _onSelectDeparture,
                        child: const Text("출발지"),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _onSelectArrival,
                        child: const Text("도착지"),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}