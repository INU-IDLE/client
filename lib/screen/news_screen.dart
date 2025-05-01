import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rushcutter/screen2/news_hidden_inquiry_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final Set<String> _unreadNewsIds = {};
  final Set<String> _unreadCategorySet = {};
  String selectedCategory = '전체';
  final List<String> categories = ['전체', '공지', '이벤트', '패치노트'];

  final List<Map<String, String>> newsList = [
    {
      'type': '공지',
      'title': '제목1',
      'date': '2025.01.20',
      'content': '내용1~~~~~~~~~~~',
      'id': 'static1',
    },
    {
      'type': '이벤트',
      'title': '제목2',
      'date': '2025.01.20',
      'content': '내용2~~~~~~~~~~~',
      'id': 'static2',
    },
  ];

  final Set<int> expandedIndices = {};
  int _tapCount = 0;
  DateTime? _lastTapTime;

  int _currentPage = 1;
  final int _itemsPerPage = 10;

  List<Map<String, String>> get _pagedNews {
    final filtered = selectedCategory == '전체'
        ? newsList
        : newsList.where((item) => item['type'] == selectedCategory).toList();
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (_currentPage * _itemsPerPage).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  int get _totalPages {
    final filtered = selectedCategory == '전체'
        ? newsList
        : newsList.where((item) => item['type'] == selectedCategory).toList();
    return (filtered.length / _itemsPerPage).ceil().clamp(1, double.infinity).toInt();
  }

  void _handleEasterEggTap() {
    final now = DateTime.now();
    if (_lastTapTime == null || now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
      _tapCount = 0;
    }
    _tapCount++;
    _lastTapTime = now;

    if (_tapCount >= 4) {
      _tapCount = 0;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NewsHiddenInquiryScreen(
            onSubmit: (Map<String, String> newItem) {
              setState(() {
                final now = DateTime.now();
                newItem['date'] = DateFormat('yyyy.MM.dd').format(now);
                final String uniqueId = now.microsecondsSinceEpoch.toString();
                newItem['id'] = uniqueId;
                newsList.insert(0, newItem);
                _unreadNewsIds.add(uniqueId);
                _unreadCategorySet.add(newItem['type'] ?? '');
              });
            },
          ),
        ),
      );
    }
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => selectedCategory = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4262C5) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            if ((label == '전체' && _unreadNewsIds.isNotEmpty) ||
                _unreadCategorySet.contains(label))
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.circle, color: Colors.red, size: 8),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(int index, Map<String, String> item) {
    final globalIndex = (_currentPage - 1) * _itemsPerPage + index;
    final itemId = item['id'];
    final isExpanded = expandedIndices.contains(globalIndex);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        color: Colors.white,
      ),
      child: Column(
        children: [
          ListTile(
            title: Row(
              children: [
                Text('[${item['type']}]',
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Text(item['title'] ?? ''),
                if (itemId != null && _unreadNewsIds.contains(itemId))
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.circle, color: Colors.red, size: 8),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(item['date'] ?? ''),
            ),
            trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() {
              isExpanded
                  ? expandedIndices.remove(globalIndex)
                  : expandedIndices.add(globalIndex);

              if (itemId != null && _unreadNewsIds.contains(itemId)) {
                _unreadNewsIds.remove(itemId);

                final itemType = item['type'];
                final stillHasUnreadOfType = newsList.any((element) =>
                _unreadNewsIds.contains(element['id']) &&
                    element['type'] == itemType);

                if (!stillHasUnreadOfType) {
                  _unreadCategorySet.remove(itemType);
                }
              }
            }),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(item['content'] ?? '', style: const TextStyle(fontSize: 14)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_totalPages, (index) {
            final pageNumber = index + 1;
            final isSelected = _currentPage == pageNumber;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: RawMaterialButton(
                onPressed: () {
                  setState(() {
                    _currentPage = pageNumber;
                  });
                },
                fillColor: isSelected ? const Color(0xFF4262C5) : Colors.transparent,
                shape: const CircleBorder(),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                elevation: 0,
                child: Text(
                  '$pageNumber',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBFF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '소식',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: _handleEasterEggTap,
                    child: Container(
                      width: 60,
                      height: 30,
                      color: Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: categories
                      .map((cat) => _buildCategoryChip(cat, selectedCategory == cat))
                      .toList(),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _pagedNews.length,
                    itemBuilder: (context, index) => _buildNewsCard(index, _pagedNews[index]),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _buildPagination(), // 동그란 RawMaterialButton 그대로
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
