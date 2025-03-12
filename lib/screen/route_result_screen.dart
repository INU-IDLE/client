import 'package:flutter/material.dart';

class RouteResultScreen extends StatelessWidget {
  final String departure;
  final String arrival;

  const RouteResultScreen({
    super.key,
    required this.departure,
    required this.arrival,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("최소 혼잡"),
        actions: [
          IconButton(
            icon: Icon(Icons.star_border),
            onPressed: () {}, // 즐겨찾기 기능 추가 가능
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ 예상 소요 시간 및 환승 정보
            Text(
              "1시간 37분",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text("환승 1회", style: TextStyle(fontSize: 16, color: Colors.grey)),

            SizedBox(height: 16),

            // ✅ 출발 및 도착 시간 표시
            Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("출발 오전 11:10", style: TextStyle(fontSize: 16)),
                  Text("도착 오후 12:13", style: TextStyle(fontSize: 16)),
                ],
              ),
            ),

            SizedBox(height: 20),

            // ✅ 경로 상세 정보
            Expanded(
              child: ListView(
                children: [
                  _buildRouteStep(
                    "11:10",
                    departure,
                    "송도달빛축제공원역 승차",
                    "인천1호선",
                    Icons.directions_subway,
                    Colors.blue,
                  ),
                  _buildTransferStep("11:46", "부평역 하차", "도보 316m"),
                  _buildRouteStep(
                    "11:51",
                    "1호선",
                    "부평역 승차",
                    "구로행",
                    Icons.directions_subway,
                    Colors.indigo,
                  ),
                  _buildArrivalStep("12:13", arrival, "구일역 하차"),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.refresh), // 🔄 경로 새로고침 아이콘
      ),
    );
  }

  // ✅ 지하철 이동 구간 UI
  Widget _buildRouteStep(
      String time,
      String station,
      String action,
      String line,
      IconData icon,
      Color color,
      ) {
    return ListTile(
      leading: Column(
        children: [
          Icon(icon, color: color, size: 30),
          Container(height: 20, width: 2, color: Colors.grey),
        ],
      ),
      title: Text("$time $line", style: TextStyle(fontSize: 16)),
      subtitle: Text("$station $action", style: TextStyle(fontSize: 14)),
    );
  }

  // ✅ 환승 구간 UI
  Widget _buildTransferStep(String time, String station, String distance) {
    return ListTile(
      leading: Column(
        children: [
          Icon(Icons.directions_walk, color: Colors.black54, size: 28),
          Container(height: 20, width: 2, color: Colors.grey),
        ],
      ),
      title: Text("$time $station", style: TextStyle(fontSize: 16)),
      subtitle: Text(distance, style: TextStyle(fontSize: 14)),
    );
  }

  // ✅ 도착역 UI
  Widget _buildArrivalStep(String time, String station, String action) {
    return ListTile(
      leading: Icon(Icons.location_on, color: Colors.red, size: 30),
      title: Text("$time $station", style: TextStyle(fontSize: 16)),
      subtitle: Text(action, style: TextStyle(fontSize: 14)),
    );
  }
}
