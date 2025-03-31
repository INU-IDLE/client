// 사용자가 출발역, 도착역 검색하는 화면
// 검색한 역을 선택하면 이전 화면으로 값 전달 (featX)
import 'package:flutter/material.dart';
import 'subway_map_screen.dart';

class SearchScreen extends StatefulWidget {
  final bool isSelectingDeparture; // 출발역 선택인지 도착역 선택인지 여부
  final String? initialQuery;

  const SearchScreen({
    required this.isSelectingDeparture,
    this.initialQuery,
    super.key,
  }); // 기본값 반드시 필요

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<String> recentSearches = []; // 최근 검색어 리스트
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode(); // 키보드 고정용 포커스 노드
  String searchQuery = ''; // 상태 변수로 searchQuery를 선언

  @override
  void initState() {
    super.initState();
    searchController.text = widget.initialQuery ?? ''; // 초기값 설정

    // 앱이 실행된 직후 키보드가 자동으로 나타나게 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(searchFocusNode); // 키보드 포커스
    });
  }

  // 검색 실행 후 SubwayMapScreen으로 이동
  void _searchAndNavigate(String query) {
    if (query.isEmpty) return;

    setState(() {
      recentSearches.remove(query); // 중복 방지
      recentSearches.insert(0, query);
    });
    searchController.clear();


    if (widget.initialQuery == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (context) =>
            SubwayMapScreen(
                searchQuery: query,
                isSelectingDeparture: widget.isSelectingDeparture),
      ),
      );
    }
    else {
      Navigator.pop(context, query); // 검색 결과 이전 화면으로 반환
    }
  }

  // 검색어 삭제
  void _deleteSearch(String query) {
    setState(() {
      recentSearches.remove(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 검색창
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 15,
              right: 15,
            ),
            child: Row(
              children: [
                // 뒤로가기 버튼
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.arrow_back, size: 24, color: Colors.black),
                ),
                SizedBox(width: 10),

                // 검색 입력창
                Expanded(
                  child: TextField(
                    controller: searchController,
                    focusNode: searchFocusNode, // 포커스 노드를 설정
                    onChanged: (text) {
                      setState(() {
                        searchQuery = text; // searchQuery 값 변경
                      });
                    },
                    onSubmitted: _searchAndNavigate, // 키보드 검색 버튼 클릭 시 실행
                    decoration: InputDecoration(
                      hintText: "지하철 역 검색",
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),

                // 돋보기 아이콘 (검색 실행)
                GestureDetector(
                  onTap: () => _searchAndNavigate(searchQuery),
                  child: Icon(Icons.search, color: Colors.black54, size: 24),
                ),
              ],
            ),
          ),

          // 최근 검색어 목록
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "최근 검색",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () => setState(() => recentSearches.clear()),
                  child: Text(
                    "삭제",
                    style: TextStyle(fontSize: 14, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),

          // 최근 검색어 리스트
          Expanded(
            child: ListView.builder(
              itemCount: recentSearches.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(recentSearches[index]),
                  leading: Icon(Icons.history, color: Colors.grey),
                  trailing: GestureDetector(
                    onTap: () => _deleteSearch(recentSearches[index]),
                    child: Icon(Icons.close, color: Colors.black54),
                  ),
                  onTap: () => _searchAndNavigate(recentSearches[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}