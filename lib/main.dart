import 'package:flutter/material.dart';
import 'package:rushcutter/screen/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // 'key' 매개변수 추가

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rushcutter', // 'title' 매개변수 정의
      theme: ThemeData(primarySwatch: Colors.blue), // 'theme' 매개변수 정의
      home: const HomeScreen(), // 'home' 매개변수 정의
    );
  }
}
