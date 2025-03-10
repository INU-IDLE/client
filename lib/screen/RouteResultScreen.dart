import 'package:flutter/material.dart';

class RouteResultScreen extends StatelessWidget {
  final String departure;
  final String destination;

  const RouteResultScreen({
    super.key, // 'key' 매개변수 추가
    required this.departure,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("경로 탐색 결과"), // 'title' 매개변수 정의
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 'mainAxisAlignment' 정의
          children: [
            Text("출발역: $departure", style: const TextStyle(fontSize: 20)), // 'style' 정의
            const SizedBox(height: 10), // 'height' 정의
            Text("도착역: $destination", style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 40),
            const Text("예상 소요 시간: 1시간 37분", style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
