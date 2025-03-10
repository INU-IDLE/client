import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'bottom_category_bar.dart';
import 'real_time_screen.dart';
import 'saved_routes_screen.dart';
import 'news_screen.dart';
import 'my_page_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'HOME'; // 선택된 카테고리
  Offset? selectedStationPosition; // 선택된 역의 위치

  @override
  Widget build(BuildContext context) {
    Widget currentScreen;

    switch (selectedCategory) {
      case 'HOME':
        currentScreen = _buildHomeContent();
        break;
      case '실시간':
        currentScreen = const RealTimeScreen();
        break;
      case '저장':
        currentScreen = const SavedRoutesScreen();
        break;
      case '소식':
        currentScreen = const NewsScreen();
        break;
      case '마이페이지':
        currentScreen = const MyPageScreen();
        break;
      default:
        currentScreen = _buildHomeContent();
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: currentScreen),
          // 상단 검색창 및 알림 버튼
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 검색창
                  Expanded(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7E7E7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: '지하철 역 검색',
                                border: InputBorder.none,
                              ),
                              onTap: () {
                                print('검색창 클릭');
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 알림 버튼
                  GestureDetector(
                    onTap: () {
                      print('알림 클릭');
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.notifications, size: 30, color: Colors.black),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Container(
                            width: 15,
                            height: 15,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '99+',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar:
      BottomCategoryBar(
        selectedCategory: selectedCategory,
        onCategorySelected: onCategorySelected,
      ),
    );
  }

  void onCategorySelected(String category) {
    setState(() {
      selectedCategory = category;
    });
  }

  Widget _buildHomeContent() {
    return SvgPicture.asset(
      "assets/images/mapimage.svg",
      fit: BoxFit.cover,
    );
  }
}
