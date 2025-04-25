import 'package:flutter/material.dart';
import 'package:rushcutter/screen2/inquiry_post_screen.dart';
import '/models/inquiry_data.dart';



class InquiryListScreen extends StatefulWidget {
  const InquiryListScreen({super.key});

  @override
  State<InquiryListScreen> createState() => _InquiryListScreenState();
}
class _InquiryListScreenState extends State<InquiryListScreen> {

  final List<InquiryData> _inquiries = [];
  final Set<int> _expandedIndices = {};
  final Map<int, bool> _unlocked = {};
  final Map<int, bool> _expanded = {};
  final GlobalKey _listKey = GlobalKey();
  double _listHeight = 0;
  String _selectedCategory = '전체';


  int _currentPage = 1;
  final int _itemsPerPage = 12;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? box = _listKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.size.height != _listHeight) {
        setState(() {
          _listHeight = box.size.height;
        });
      }
    });
  }


  int get _totalPages {
    final filtered = _selectedCategory == '전체'
        ? _inquiries
        : _inquiries.where((q) => q.category == _selectedCategory).toList();
    return (filtered.isEmpty) ? 1 : (filtered.length / _itemsPerPage).ceil();
  }
  List<InquiryData> get _pagedInquiries {
    final filtered = _selectedCategory == '전체'
        ? _inquiries
        : _inquiries.where((q) => q.category == _selectedCategory).toList();

    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (_currentPage * _itemsPerPage).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }



  Future<String?> _showPasswordDialog() async {
    String pw = '';
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('비밀번호 입력'),
        content: TextField(
          onChanged: (val) => pw = val,
          obscureText: true,
          decoration: const InputDecoration(hintText: '4자리 비밀번호'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, pw), child: const Text('확인')),
        ],
      ),
    );
  }

  void _navigateToPost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InquiryPostScreen()),
    );

    if (result is Map && result['post'] is InquiryData) {
      final post = result['post'] as InquiryData;
      final editIndex = result['editIndex'] as int?;

      setState(() {
        if (editIndex != null) {
          _inquiries[editIndex] = post;
        } else {
          _inquiries.insert(0, post);
        }
      });
    }
  }



  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalPages, (index) {
        final pageNumber = index + 1;
        final isSelected = _currentPage == pageNumber;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _currentPage = pageNumber;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
              minimumSize: const Size(32, 32),
              padding: EdgeInsets.zero,
            ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final estimatedHeight = _pagedInquiries.length * 50;
    final screenHeight = MediaQuery.of(context).size.height;
    final shouldStickPaginationAtBottom = estimatedHeight + 200 < screenHeight;
    return Scaffold(
      bottomNavigationBar: (!shouldStickPaginationAtBottom)
          ? null
          : Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: _buildPagination(),
      ),



      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0, // 기본 그림자 제거nter(child: Text
        title: const Text('문의하기 / 오류 신고'),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade300, // 하단 선 색상
          ),
        ),
      ),

      backgroundColor: Colors.white,


      body : LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              SingleChildScrollView(
                child: Container(
                  key: _listKey,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 30), // ← 여기 숫자 조절하면 높이 바뀜
                            child: Text(
                              '답변대기: ${_inquiries.where((e) => !e.isAnswered).length} / 답변완료: ${_inquiries.where((e) => e.isAnswered).length}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                          SizedBox(
                            height: 48,
                            width: 100,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: DropdownMenu<String>(
                                initialSelection: '전체',
                                menuStyle: const MenuStyle(
                                  backgroundColor: WidgetStatePropertyAll(Color(0xFFEBF0FF)), // ✅ 파란 배경 적용
                                ),
                                dropdownMenuEntries: [
                                  DropdownMenuEntry(
                                    value: '전체',
                                    label: '전체',
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                                      overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
                                        if (states.contains(WidgetState.pressed)) {
                                          return Colors.grey.withAlpha((0.1 * 255).toInt());
                                        }
                                        return Colors.transparent;
                                      }),
                                    ),
                                  ),
                                  DropdownMenuEntry(
                                    value: '문의',
                                    label: '문의',
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                                      overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
                                        if (states.contains(WidgetState.pressed)) {
                                          return Colors.grey.withAlpha((0.1 * 255).toInt());
                                        }
                                        return Colors.transparent;
                                      }),
                                    ),
                                  ),
                                  DropdownMenuEntry(
                                    value: '오류',
                                    label: '오류',
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                                      overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
                                        if (states.contains(WidgetState.pressed)) {
                                          return Colors.grey.withAlpha((0.1 * 255).toInt());
                                        }
                                        return Colors.transparent;
                                      }),
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  setState(() {
                                    _selectedCategory = value ?? '전체';
                                    _currentPage = 1; // 페이지도 초기화하는 게 좋아
                                  });
                                },
                                inputDecorationTheme: const InputDecorationTheme(
                                  isCollapsed: true,
                                  contentPadding: EdgeInsets.only(left: 12),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_pagedInquiries.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: Text('작성된 게시글이 없습니다.')),
                        )
                      else

                        ..._pagedInquiries.asMap().entries.map((entry) {
                          final index = entry.key;
                          final data = entry.value;
                          final realIndex = (_currentPage - 1) * _itemsPerPage + index;
                          final isExpanded = _expanded[index] ?? false;

                          return Column(
                            children: [
                              Container(
                                color: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '[${data.category}]',
                                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            data.title,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Icon(
                                          data.isPrivate
                                              ? (_unlocked[index] == true ? Icons.lock_open : Icons.lock)
                                              : Icons.lock_open,
                                          size: 18,
                                        ),
                                        IconButton(
                                          icon: Icon(
                                              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                                          onPressed: () async {
                                            if (!data.isPrivate) {
                                              setState(() {
                                                _expanded[index] = !(_expanded[index] ?? false);
                                              });
                                              return;
                                            }

                                            if (_unlocked[index] == true) {
                                              setState(() {
                                                _expanded[index] = !(_expanded[index] ?? false);
                                              });
                                              return;
                                            }

                                            final pw = await _showPasswordDialog();

                                            if (pw == data.password) {
                                              if (!context.mounted) return;
                                              setState(() {
                                                _unlocked[index] = true;
                                                _expanded[index] = true;
                                              });
                                            } else if (pw != null) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('비밀번호가 틀렸습니다.')),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    Text('${data.date} · ${data.author}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    if (isExpanded) ...[
                                      const SizedBox(height: 12),
                                      Text(data.content),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          GestureDetector(
                                            onTap: () async {
                                              final result = await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => InquiryPostScreen(
                                                    initialTitle: data.title,
                                                    initialContent: data.content,
                                                    initialCategory: data.category,
                                                    editIndex: realIndex,
                                                  ),
                                                ),
                                              );

                                              if (result is Map && result['post'] is InquiryData) {
                                                final post = result['post'] as InquiryData;
                                                final editIndex = result['editIndex'] as int?;

                                                if (editIndex != null) {
                                                  setState(() {
                                                    _inquiries[editIndex] = post;
                                                  });
                                                }
                                              }
                                            },
                                            child: const Text('수정', style: TextStyle(color: Colors.blue)),
                                          ),
                                          const SizedBox(width: 12),
                                          GestureDetector(
                                            onTap: () async {
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: const Text('삭제 확인'),
                                                  content: const Text('정말 삭제하시겠습니까?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context, false),
                                                      child: const Text('취소'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context, true),
                                                      child: const Text('확인'),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirm == true) {
                                                setState(() {
                                                  _inquiries.removeAt(realIndex);
                                                  _expanded.remove(index);
                                                  _expandedIndices.remove(index);
                                                  _unlocked.remove(index);
                                                });
                                              }
                                            },
                                            child: const Text('삭제', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                              const Divider(height: 1, thickness: 1, color: Colors.grey),
                            ],
                          );
                        }),
                      const SizedBox(height: 12),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToPost,
        backgroundColor: Colors.white,
        child: const Icon(Icons.edit, color: Colors.black),
      ),
    );
  }
}
