import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'bottom_category_bar.dart';
import 'real_time_screen.dart';
import '../screen2/saved_routes_screen.dart';
import 'news_screen.dart';
import 'my_page_screen.dart';
import 'search_screen.dart'; // SearchScreen 추가

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'HOME'; // 선택된 카테고리
  Offset? selectedStationPosition; // 선택된 역의 위치
  String? departureStation; // 출발역
  String? arrivalStation; // 도착역

  final TransformationController _transformationController = TransformationController(); // transformation 추가

  @override
  void initState() {
    super.initState();

    // 초기 줌 상태 설정
    _transformationController.value = Matrix4.identity()..scale(4.0); // 초기스케일
  }
  void onCategorySelected(String category) {
    setState(() {
      selectedCategory = category;
    });
  }

  // 검색 결과를 처리하는 메서드
  void _handleSearchResult(String? result, bool isSelectingDeparture) {
    if (result != null) {
      setState(() {
        if (isSelectingDeparture) {
          departureStation = result;
        } else {
          arrivalStation = result;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 상태바 높이를 가져옴
    final double statusBarHeight = MediaQuery.of(context).padding.top;

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
            top: statusBarHeight, // 상태바 바로 아래부터 시작
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
                            child: GestureDetector(
                              onTap: () async {
                                // 검색창 클릭 시 SearchScreen으로 이동
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SearchScreen(
                                      isSelectingDeparture: true, // 기본값 설정
                                    ),
                                  ),
                                );
                                // 검색 결과 처리
                                _handleSearchResult(result, true);
                              },
                              child: Text(
                                departureStation ?? '지하철 역 검색',
                                style: const TextStyle(color: Colors.black),
                              ),
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
      bottomNavigationBar: BottomCategoryBar(
        selectedCategory: selectedCategory,
        onCategorySelected: onCategorySelected,
      ),
    );
  }


  Widget _buildHomeContent() {
    return Stack(
      children: [
        InteractiveViewer(
          minScale: 2.0, // 최대 줌 아웃 비율
          maxScale: 7.0, // 최소 줌 인 비율
          boundaryMargin: const EdgeInsets.all(20), // 화면 경계 여백 설정
          child: SvgPicture.asset(
            "assets/images/metropolitan.svg", // SVG 파일 경로
            fit: BoxFit.contain, // 이미지 크기 맞추기
            allowDrawingOutsideViewBox: true,
            placeholderBuilder: (BuildContext context) => const CircularProgressIndicator(), // 로딩 중 표시
            errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
              return const Center(
                  child: Text("SVG 파일을 로드할 수 없습니다.")); // 오류 발생 시 메시지 출력\
            },
          ),
        ),
        // 출발역과 도착역 표시
        if (departureStation != null || arrivalStation != null)
          Positioned(
            top: 20,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (departureStation != null)
                  Text(
                    '출발역: $departureStation',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (arrivalStation != null)
                  Text(
                    '도착역: $arrivalStation',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
