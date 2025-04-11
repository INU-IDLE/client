import 'package:flutter/material.dart';
import 'screen/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:rushcutter/screen/home_screen.dart';
import 'package:rushcutter/screen/congestion_prediction_screen.dart';
import 'package:rushcutter/providers/saved_route_provider.dart';


void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SavedRouteProvider()), // ✅ 등록
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // 'key' 매개변수 추가

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rushcutter', // 'title' 매개변수 정의
      theme: ThemeData(primarySwatch: Colors.blue), // 'theme' 매개변수 정의
      home: const HomeScreen(), // 'home' 매개변수 정의
      routes: {
        '/congestion': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
          return const CongestionPredictionScreen();
        },
      },
    );
  }
}









