import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screen/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:rushcutter/layout/main_layout.dart';
import 'package:rushcutter/screen/congestion_prediction_screen.dart';
import 'package:rushcutter/providers/saved_route_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const MainLayout(),
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
