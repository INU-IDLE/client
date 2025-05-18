import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rushcutter/screen/saved_routes_screen.dart';
import 'package:rushcutter/screen/news_screen.dart';
import 'package:rushcutter/screen/my_page_screen.dart';
import 'package:rushcutter/screen/search_screen.dart';
import 'package:rushcutter/widgets/station_component.dart';
import 'package:rushcutter/models/station.dart';
import 'package:rushcutter/screen/subway_map_screen.dart';
import 'package:rushcutter/data/station_data.dart';
import '../screen2/subway_line_select_screen.dart';

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
        currentScreen = const SubwayLineSelectScreen();
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
                        left: (buttonStation.cx) - 40,
                        top: (buttonStation.cy) - 120,
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
                              child: Column(
                                children: [
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
                                  ),
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