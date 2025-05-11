import 'package:flutter/material.dart';
import 'subway_map_screen.dart';
import 'dart:convert';

class SearchScreen extends StatefulWidget {
  final bool isSelectingDeparture;
  final String? initialQuery;

  const SearchScreen({
    required this.isSelectingDeparture,
    this.initialQuery,
    super.key,
  });

  @override
  _SearchScreenState createState() => _SearchScreenState();
}


class _SearchScreenState extends State<SearchScreen> {
  List<String> recentSearches = []; // 최근 검색어 리스
  List<dynamic> stationList = []; // 역 정보 리스트 (json)
  List<String> suggestions = []; // 자동완성 리스트
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode(); // 키보드 고정용 포커스 노드
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    searchController.text = widget.initialQuery ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      FocusScope.of(context).requestFocus(searchFocusNode); // 키보드 포커스

      // JSON 불러오기
      final jsonString = await DefaultAssetBundle.of(context).loadString(
          'assets/station_info.json');
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      setState(() {
        stationList = jsonMap['DATA'];
      });
    });
    // 앱이 실행된 직후 키보드가 자동으로 나타나게 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(searchFocusNode); // 키보드 포커스
    });
  }

  // 검색 실행 후 SubwayMapScreen으로 이동
  Future<void> _searchAndNavigate(String query) async {
    if (query.isEmpty) return;

    // 변경된 경로
    final jsonString = await DefaultAssetBundle.of(context).loadString(
        'assets/station_info.json');
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    final List<dynamic> stationList = jsonMap['DATA'];
    final queryTrimmed = query.replaceAll('역', '');
    final exists = stationList.any((station) {
      final name = station['station_nm'] ?? '';
      return name == query || name == queryTrimmed;
    });

    if (!exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('존재하지 않는 역입니다.')),
      );
      return;
    }

    final displayQuery = stationList.firstWhere(
          (station) {
        final name = station['station_nm'] ?? '';
        return name == query || name == queryTrimmed;
      },
    )['station_nm'];
// 최근 검색어 업데이트
    if (mounted) {
      setState(() {
        recentSearches.remove(displayQuery);
        recentSearches.insert(0, displayQuery);
        if (recentSearches.length > 10)
          recentSearches = recentSearches.sublist(0, 10);
      });
    }

    if (widget.initialQuery == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (ctx) =>
              SubwayMapScreen(
                searchQuery: displayQuery,
                isSelectingDeparture: widget.isSelectingDeparture,
                selectedStation: null,
              ),
        ),
      );
    } else {
      Navigator.pop(context, displayQuery);
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
              top: MediaQuery
                  .of(context)
                  .padding
                  .top + 10,
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7E7E7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            focusNode: searchFocusNode,
                            onChanged: (text) {
                              final cleaned = text.replaceAll('역', '');
                              setState(() {
                                searchQuery = cleaned;
                                final lowerText = cleaned.toLowerCase();
                                suggestions = stationList
                                    .map((s) => s['station_nm'].toString())
                                    .where((name) =>
                                    name.toLowerCase().contains(lowerText))
                                    .toSet()
                                    .toList();
                              });
                            },
                            onSubmitted: _searchAndNavigate,
                            decoration: InputDecoration(
                              hintText: "지하철 역 검색",
                              hintStyle: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 17,
                                fontWeight: FontWeight.w500, // 필요시 두께 조정
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 14),
                            ),
                            style: TextStyle(fontSize: 17,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _searchAndNavigate(searchQuery),
                          child: Icon(Icons.search, color: Colors.black54,
                              size: 24),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 최근 검색어 목록
          if (recentSearches.isNotEmpty) ...[
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
                      "전체 삭제",
                      style: TextStyle(fontSize: 14, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 15),
                itemCount: recentSearches.length,
                separatorBuilder: (_, __) => SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final query = recentSearches[index];
                  return Chip(
                    label: Text(query),
                    deleteIcon: Icon(Icons.close, size: 18),
                    onDeleted: () => _deleteSearch(query),
                    backgroundColor: Colors.grey[200],
                  );
                },
              ),
            ),
          ],

          // 검색 결과 목록
          Expanded(
            child: suggestions.isNotEmpty
                ? ListView.separated(
              padding: EdgeInsets.only(top: 10),
              itemCount: suggestions.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey[300]),
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return ListTile(
                  leading: Icon(Icons.subway, color: Colors.blue),
                  title: Text(
                    suggestion,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  trailing: Icon(
                      Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () => _searchAndNavigate(suggestion),
                );
              },
            )
                : Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  recentSearches.isEmpty
                      ? "검색어를 입력해주세요"
                      : "검색 결과가 없습니다.",
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}