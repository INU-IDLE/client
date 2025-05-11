import 'package:flutter/material.dart';
import 'package:rushcutter/screen/home_screen.dart';
import 'package:rushcutter/screen/news_screen.dart';
import 'package:rushcutter/screen/my_page_screen.dart';
import 'package:rushcutter/screen/saved_routes_screen.dart';
import 'package:rushcutter/screen/bottom_category_bar.dart';
import 'package:rushcutter/screen2/subway_line_select_screen.dart';


class MainLayout extends StatefulWidget {
  final String initialCategory;
  final Widget? customContent; // 👈 여기 추가

  const MainLayout({
    super.key,
    this.initialCategory = 'HOME',
    this.customContent,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late String selectedCategory;

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory;
  }

  Widget _getSelectedScreen() {
    if (widget.customContent != null) {
      return widget.customContent!;
    }

    switch (selectedCategory) {
      case 'HOME':
        return const HomeScreen();
      case '시간표':
        return const SubwayLineSelectScreen();
      case '저장':
        return const SavedRoutesScreen();
      case '소식':
        return const NewsScreen();
      case 'MY':
        return const MyPageScreen();
      default:
        return const HomeScreen();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getSelectedScreen(),
      bottomNavigationBar: BottomCategoryBar(
        selectedCategory: selectedCategory,
        onCategorySelected: (category) {
          setState(() {
            selectedCategory = category;
          });
        },
      ),
    );
  }
}
