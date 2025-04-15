import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'shared/providers/station_provider.dart';
import 'screen/home_screen.dart';

void main() {
  runApp(
      ChangeNotifierProvider(
        create: (_) => StationProvider(),
        child: MyApp(),
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
      home: HomeScreen(), // 'home' 매개변수 정의
    );
  }
}

