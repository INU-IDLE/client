import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Subway App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SubwayMapScreen(searchQuery: "송도달빛축제공원역", isSelectingDeparture: true),
    );
  }
}

// SubwayMapScreen 코드
class SubwayMapScreen extends StatefulWidget {
  final String searchQuery;
  final bool isSelectingDeparture; // 출발역 선택인지 도착역 선택인지 여부

  const SubwayMapScreen({
    required this.searchQuery,
    required this.isSelectingDeparture,
  });

  @override
  _SubwayMapScreenState createState() => _SubwayMapScreenState();
}

class _SubwayMapScreenState extends State<SubwayMapScreen> {
  String? departureStation; // 출발역
  String? arrivalStation;   // 도착역
  String? searchedStation;  // 검색한 역
  bool showButtons = false; // 버튼을 표시할지 여부

  @override
  void initState() {
    super.initState();
    searchedStation = widget.searchQuery; // 검색어로 초기화
    if (widget.isSelectingDeparture) {
      departureStation = "출발역"; // 출발역 기본 텍스트
      arrivalStation = "도착역";   // 도착역 기본 텍스트
    }
  }

  // 출발역 설정
  void _setDeparture() {
    setState(() {
      departureStation = searchedStation;
    });
  }

  // 도착역 설정
  void _setArrival() {
    setState(() {
      arrivalStation = searchedStation;
    });
  }

  // 출발역과 도착역을 교환
  void swapStations() {
    setState(() {
      String? temp = departureStation;
      departureStation = arrivalStation;
      arrivalStation = temp;
    });
  }

  // 출발역과 도착역을 선택하는 UI
  Widget _buildStationBox(String text) {
    return Container(
      height: 50,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Text(text, style: TextStyle(color: Colors.black87, fontSize: 18)),
    );
  }

  // 선택 버튼 UI
  Widget _buildSelectButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 5,
              offset: Offset(3, 3),
            ),
          ],
        ),
        child: Text(text, style: TextStyle(color: Colors.black, fontSize: 16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 상단 검색 UI 제거 (SearchScreen에서만 검색창이 있어야 함)

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
                  child: Icon(Icons.close, size: 28, color: Colors.black),
                ),
                SizedBox(width: 10),

                Expanded(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _setDeparture,
                        child: _buildStationBox(
                          departureStation ?? "출발역", // 기본값 "출발역"
                        ), // 버튼 클릭 시 출발역 설정
                      ),
                      SizedBox(height: 8),
                      GestureDetector(
                        onTap: _setArrival,
                        child: _buildStationBox(
                          arrivalStation ?? "도착역", // 기본값 "도착역"
                        ), // 버튼 클릭 시 도착역 설정
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 10),

                GestureDetector(
                  onTap: swapStations,
                  child: Icon(Icons.swap_vert, size: 28, color: Colors.black),
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
                    child: Center(child: Text("🚇 지하철 노선도 표시")),
                  ),
                ),
                // 버튼을 노선도 위에 고정
                Positioned(
                  left: 50,
                  top: 150,
                  child: Column(
                    children: [
                      _buildSelectButton("출발지", _setDeparture),
                      SizedBox(height: 8),
                      _buildSelectButton("도착지", _setArrival),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // 하단 네비게이션 바 UI
  Widget _buildBottomNavBar() {
    return Container(
      height: 60,
      color: Colors.white,
      child: Row(
        children: [
          _buildNavItem(Icons.home, "HOME"),
          _buildNavItem(Icons.directions_transit, "실시간"),
          _buildNavItem(Icons.favorite_border, "저장"),
          _buildNavItem(Icons.article, "소식"),
          _buildNavItem(Icons.person, "마이페이지"),
        ],
      ),
    );
  }

  // 네비게이션 아이템 UI
  Widget _buildNavItem(IconData icon, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
