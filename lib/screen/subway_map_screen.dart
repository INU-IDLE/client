import 'package:flutter/material.dart';
import '../models/station.dart';
import 'search_screen.dart';
import 'route_result_screen.dart';
import 'dart:ui';
import 'home_screen.dart';
import 'package:rushcutter/widgets/station_component.dart';
import 'package:rushcutter/data/station_data.dart';
import 'package:rushcutter/screen/home_screen.dart';
import 'bottom_category_bar.dart';

class SubwayMapScreen extends StatefulWidget {
  final String? searchQuery;
  final bool isSelectingDeparture;
  final dynamic selectedStation;
  final Matrix4? initialTransformation; // 필수 파라미터로 변경
  final String? selectedStationId;
  // 출발역 도착역 빈칸 선택 여부, T = 출발역 빈칸, F = 도착역 빈칸
  // final Station selectedStation;


  const SubwayMapScreen({
    // this.searchQuery,
    required this.isSelectingDeparture,
    this.searchQuery,
    required this.selectedStation,
    this.initialTransformation,
    this.selectedStationId,
    super.key,
  });


  @override
  State<SubwayMapScreen> createState() => _SubwayMapScreenState();
}

class _SubwayMapScreenState extends State<SubwayMapScreen> {
  late final TransformationController _transformationController; // 추가
  // late StationService _stationService;
  Station? selectedStation;
  String? departureStation; // 출발역
  String? arrivalStation; // 도착역
  String? searchedStation; // 검색한 역
  bool showDepartureButton = true; // 출발지 버튼 표시 여부
  bool showArrivalButton = true; // 도착지 버튼 표시 여부
  late TextEditingController _departureController;
  late TextEditingController _arrivalController;
  String? selectedStationId;


  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController(
      widget.initialTransformation ?? Matrix4.identity(),
    );
    searchedStation = widget.searchQuery; // 검색어로 초기화
    // 검색 결과 기반 초기 설정
    if (widget.searchQuery != null) {
      final station = stationData.firstWhere(
            (s) => s.stationNm == widget.searchQuery,
        orElse: () => Station(id: '', cx: 0, cy: 0, r: 0, stationNm: '', line: ''),
      );

      if (station.id.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _transformationController.value = Matrix4.identity()
            ..translate(
                -station.cx * 1.3 + MediaQuery.of(context).size.width / 2,
                -station.cy * 1.3 + MediaQuery.of(context).size.height / 2
            )
            ..scale(1.3);

          setState(() {
            selectedStationId = station.id; // ★ 추가
            selectedStation = station; // ★ 추가
          });
        });
      }
    }
  }

  void _onSelectDeparture() {
    setState(() {
      departureStation = selectedStation?.stationNm;
      //showDepartureButton = false;
      //showArrivalButton = false;
      //selectedStation = null; // 선택 해제
      //selectedStationId = null;
    });
  }

  void _onSelectArrival() {
    setState(() {
      arrivalStation = selectedStation?.stationNm;
      //showDepartureButton = false;
      //showArrivalButton = false;
      //selectedStation = null; // 선택 해제
      //selectedStationId = null;
    });
  }

  void _handleStationTap(String? stationId) {
    setState(() {
      selectedStationId = stationId;
      selectedStation = stationId != null
          ? stationData.firstWhere((s) => s.id == stationId)
          : null;
    });
  }

  // 출발지 버튼 클릭 시 searchQuery 값 출발역에 반영
  void _setDepartureFromButton(){
    setState(() {
      if (widget.searchQuery != null){
        departureStation = widget.searchQuery;
        showDepartureButton = false;
        showArrivalButton = false;
      }
    });
  }

  // 도착지 버튼 클릭 시 searchQuery 값 도착역에 반영
  void _setArrivalFromButtton(){
    setState(() {
      if (widget.searchQuery != null){
        arrivalStation = widget.searchQuery;
        showDepartureButton = false;
        showArrivalButton = false;
      }
    });
  }


  // 출발역 설정 (빈칸 클릭 시)
  void _setDeparture() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => SearchScreen(
          isSelectingDeparture: false,
          initialQuery: departureStation ?? "", // 이전 입력값 전달 (null이면 빈 문자열)
        ),
      ),
    );
    if (result != null) {
      setState(() {
        departureStation = result; // 검색 결과를 출발역에 반영
      });
    }
  }

  // 도착역 설정 (빈칸 클릭 시)
  void _setArrival() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => SearchScreen(
          isSelectingDeparture: false,
          initialQuery: arrivalStation ?? "", // 이전 입력값 전달 (null이면 빈 문자열)
        ),
      ),
    );
    if (result != null) {
      setState(() {
        arrivalStation = result; // 검색 결과를 도착역에 반영
      });
    }
  }


  // 출발역과 도착역 교환
  void swapStations() {
    if (departureStation == null || arrivalStation == null) return;
    setState(() {
      String? temp = departureStation;
      departureStation = arrivalStation;
      arrivalStation = temp;
    });
  }

  // 검색 버튼 클릭 -> 결과 화면으로 이동
  void navigateToResult() {
    if (departureStation == null || arrivalStation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("출발역과 도착역을 모두 입력해주세요.")),
      );
      return;
    }

    if (departureStation == arrivalStation){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("출발역과 도착역이 동일할 수 없습니다.")),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouteResultScreen(
          departure: departureStation!,
          arrival: arrivalStation!,
        ),
      ),
    );
  }

  // 출발역과 도착역 빈칸 생성
  Widget buildStationBox(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap, // 클릭 시 검색 화면으로 이동
      child: Container(
        height: 50,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Text(
          text,
          style: const TextStyle(color: Colors.black87, fontSize: 18),
        ),
      ),
    );
  }

  // 선택 버튼 UI 생성
  Widget buildSelectButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        onTap();
      }, // 임시 저장 결과 실제 빈칸(출발역/도착역)에 입력
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 5,
              offset: const Offset(3, 3),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 출발역/도착역 설정 UI
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 15,
              right: 15,
              bottom: 20,
            ),
            color: Colors.white,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 28, color: Colors.black),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      buildStationBox(
                          departureStation ?? "출발역", _setDeparture),
                      const SizedBox(height: 8),
                      buildStationBox(arrivalStation ?? "도착역", _setArrival),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: navigateToResult,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text("검색"),
                ),
                GestureDetector(
                  onTap: swapStations,
                  child: const Icon(Icons.swap_vert, size: 28, color: Colors.black),
                ),
              ],
            ),
          ),

          // 지하철 노선도 & 선택 버튼
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque, // 빈 공간 터치 인식!
              onTap: () {
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
                        onStationTap: _handleStationTap
                      ),
                      if (selectedStation != null &&
                          selectedStation!.id.isNotEmpty)
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
          ),
          ),
          ],
      ),
      bottomNavigationBar: buildBottomNavBar(),
    );
  }


  Widget buildBottomNavBar() {
    return Container(
      height: 60,
      color: Colors.white,
      child: Row(
        children: [
          buildNavItem(Icons.home, "HOME"),
          buildNavItem(Icons.directions_transit, "실시간"),
          buildNavItem(Icons.favorite_border, "저장"),
          buildNavItem(Icons.article, "소식"),
          buildNavItem(Icons.person, "마이페이지"),
        ],
      ),
    );
  }

  Widget buildNavItem(IconData icon, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}