import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screen/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:rushcutter/screen/congestion_prediction_screen.dart';
import 'package:rushcutter/providers/saved_route_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // .env 파일 로드

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white, // 상태바 배경 흰색
      statusBarIconBrightness: Brightness.dark, // 안드로이드: 아이콘 검정
      statusBarBrightness: Brightness.light,    // iOS: 아이콘 검정
    ),
  );
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
        theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        ),
      home: const HomeScreen(),
      routes: {
        '/congestion': (context) {
          return const CongestionPredictionScreen();
        },
      },
    );
  }
}
