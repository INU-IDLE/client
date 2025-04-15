import 'package:flutter/material.dart';
import '../models/station.dart';
import 'search_screen.dart';
import 'route_result_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rushcutter/services/station_service.dart';
import 'dart:ui';
import 'package:rushcutter/shared/providers/station_provider.dart'; // StationProvider for managing state


class SubwayMapScreen extends StatefulWidget {
  final String? searchQuery;
  final bool isSelectingDeparture;
  final dynamic selectedStation;
  final Matrix4? initialTransformation;
  // 출발역 도착역 빈칸 선택 여부, T = 출발역 빈칸, F = 도착역 빈칸
  // final Station selectedStation;

  const SubwayMapScreen({
    // this.searchQuery,
    required this.isSelectingDeparture,
    this.searchQuery,
    required this.selectedStation,
    this.initialTransformation,
    super.key,
  });


  @override
  State<SubwayMapScreen> createState() => _SubwayMapScreenState();
}

class _SubwayMapScreenState extends State<SubwayMapScreen> {
  // late StationService _stationService;
  Station? selectedStation;
  String? departureStation; // 출발역
  String? arrivalStation; // 도착역
  String? searchedStation; // 검색한 역
  bool showDepartureButton = true; // 출발지 버튼 표시 여부
  bool showArrivalButton = true; // 도착지 버튼 표시 여부
  late TextEditingController _departureController;
  late TextEditingController _arrivalController;

  final List<Station> stations = [
    Station(id: "234", cx: 505.35, cy: 500.06, r: 20, stationNm: "신도림", line: "02호선"),
    Station(id: "208", cx: 822.85, cy: 386.29, r: 20, stationNm: "왕십리", line: "02호선"),
    // ... 추가
  ];

  @override
  void initState() {
    super.initState();
    searchedStation = widget.searchQuery; // 검색어로 초기화
    // 출발역/도착역 초기화
    if (widget.isSelectingDeparture) {
      departureStation = widget.searchQuery ?? "";
      _departureController = TextEditingController(text: departureStation);
      _arrivalController = TextEditingController(text: "");
    } else {
      arrivalStation = widget.searchQuery ?? "";
      _departureController = TextEditingController(text: "");
      _arrivalController = TextEditingController(text: arrivalStation);
    }

    // 처음 selectedStation도 세팅해두면 추후 노선도 버튼 활성화 가능
    selectedStation = widget.selectedStation;
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
          isSelectingDeparture: true,
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
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    color: Colors.grey[200],
                    child: Image.asset(
                      "assets/images/metropolitan.png", // SVG 파일 경로
                      width: 4500,
                      height: 3800,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (selectedStation != null)
                Positioned(
                  left: selectedStation?.cx,
                  top: selectedStation?.cy,
                  child: Column(
                    children: [
                      if (selectedStation != null && showArrivalButton)
                        GestureDetector(
                          onTap: _setDepartureFromButton,
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
                            child: const Text("출발지", style: TextStyle(color: Colors.black, fontSize: 16),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (selectedStation != null && showDepartureButton)
                        GestureDetector(
                          onTap: _setArrivalFromButtton,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 5,
                                  offset: const Offset(3,3),
                                ),
                              ],
                            ),
                            child: const Text("도착지", style: TextStyle(color: Colors.black, fontSize: 16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
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