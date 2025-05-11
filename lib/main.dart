import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rushcutter/layout/main_layout.dart';
import 'package:rushcutter/screen/congestion_prediction_screen.dart';
import 'package:rushcutter/providers/saved_route_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SavedRouteProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rushcutter',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainLayout(), // 🔁 여기서 MainLayout 사용
      routes: {
        '/timetable': (context) => const MainLayout(initialCategory: '시간표'),
        '/news': (context) => const MainLayout(initialCategory: '소식'),
        '/saved': (context) => const MainLayout(initialCategory: '저장'),
        '/mypage': (context) => const MainLayout(initialCategory: 'MY'),
        '/congestion': (context) => const CongestionPredictionScreen(),
      },
    );
  }
}
