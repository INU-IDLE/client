import 'package:flutter/material.dart';
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
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rushcutter',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),

      routes: {
        '/congestion': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
          return const CongestionPredictionScreen();
        },
      },
    );
  }
}
