import 'package:flutter/material.dart';
import 'route_result_screen.dart';
import 'search_screen.dart';

class SubwayMapScreen extends StatefulWidget {
  final String searchQuery;
  final bool isSelectingDeparture;

  const SubwayMapScreen({
    required this.searchQuery,
    required this.isSelectingDeparture,
  });

  @override
  _SubwayMapScreenState createState() => _SubwayMapScreenState();
}

class _SubwayMapScreenState extends State<SubwayMapScreen> {
  String? departureStation;
  String? arrivalStation;
  String? searchedStation;

  @override
  void initState() {
    super.initState();

    // ✅ 초기 검색 값은 저장되지 않음 (출발지 도착지 버튼 누르기 전까지)
    searchedStation = widget.searchQuery;
    if (widget.isSelectingDeparture) {
      departureStation = null;
      arrivalStation = null;
    }
  }

  // ✅ 출발역 설정
  void _setDeparture() {
    if (searchedStation != null && searchedStation!.isNotEmpty) {
      setState(() {
        departureStation = searchedStation;
      });
    }
  }

  // ✅ 도착역 설정
  void _setArrival() {
    if (searchedStation != null && searchedStation!.isNotEmpty) {
      setState(() {
        arrivalStation = searchedStation;
      });
    }
  }

  // ✅ 출발역과 도착역 교환
  void swapStations() {
    setState(() {
      String? temp = departureStation;
      departureStation = arrivalStation;
      arrivalStation = temp;
    });
  }

  // ✅ 팝업 표시 함수
  void _showAlertDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("안내"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("확인"),
            ),
          ],
        );
      },
    );
  }

  // ✅ 경로 결과 화면으로 이동
  // ✅ 경로 결과 화면으로 이동
  void _navigateToRouteResult() {
    if (departureStation == null && arrivalStation == null) {
      _showAlertDialog("출발역과 도착역을 지정해주세요!");
    } else if (departureStation == null) {
      _showAlertDialog("출발역을 지정해주세요!");
    } else if (arrivalStation == null) {
      _showAlertDialog("도착역을 지정해주세요!");
    } else {
      // ✅ 널 체크 추가
      if (departureStation != null && arrivalStation != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RouteResultScreen(
              departure: departureStation ?? '',
              arrival: arrivalStation ?? '',
            ),
          ),
        );
      }
    }
  }


  // ✅ 출발역/도착역 회색 창 클릭 → SearchScreen으로 이동
  Future<void> _selectStation(bool isDeparture) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchScreen(
          isSelectingDeparture: isDeparture,
        ),
      ),
    );

    if (result != null) {
      // ✅ 즉시 값 반영하도록 수정
      setState(() {
        if (isDeparture) {
          departureStation = result; // ✅ 즉시 반영
        } else {
          arrivalStation = result; // ✅ 즉시 반영
        }
      });
    }
  }

  // ✅ 출발역/도착역 표시 박스 (값 자동 반영)
  Widget _buildStationBox(String? text, String placeholder, bool isDeparture) {
    return GestureDetector(
      onTap: () async {
        // ✅ SearchScreen에서 값 받아오기
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchScreen(
              isSelectingDeparture: isDeparture,
            ),
          ),
        );

        if (result != null) {
          setState(() {
            if (isDeparture) {
              departureStation = result; // ✅ 즉시 반영
            } else {
              arrivalStation = result;
            }
          });
        }
      },
      child: Container(
        height: 44,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          text ?? placeholder,
          style: const TextStyle(color: Colors.black87, fontSize: 16),
        ),
      ),
    );
  }

  // ✅ 출발지/도착지 버튼 UI
  Widget _buildSelectButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 5,
              offset: Offset(3, 3),
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
          // ✅ 상단 닫기 버튼 + 출발역/도착역 설정 UI
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 15,
              right: 15,
              bottom: 15,
            ),
            color: Colors.white,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 28, color: Colors.black),
                ),
                const SizedBox(width: 10),

                // ✅ 출발역/도착역 표시 박스
                Expanded(
                  child: Column(
                    children: [
                      _buildStationBox(departureStation, "출발역", true),
                      const SizedBox(height: 8),
                      _buildStationBox(arrivalStation, "도착역", false),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                Column(
                  children: [
                    GestureDetector(
                      onTap: swapStations,
                      child: const Icon(Icons.swap_vert, size: 28, color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _navigateToRouteResult,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.search, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ✅ 출발지/도착지 버튼 추가
          // ✅ 137줄 ~ Expanded 부분 수정
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSelectButton("출발지", _setDeparture),
                const SizedBox(height: 8),
                _buildSelectButton("도착지", _setArrival),
                const SizedBox(height: 30),

                // ✅ 여기에 파란색 검색 버튼 추가
                GestureDetector(
                  onTap: _navigateToRouteResult,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.search, color: Colors.white, size: 30),
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}