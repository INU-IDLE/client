import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/models/inquiry_data.dart';


class InquiryPostScreen extends StatefulWidget {
  final String? initialTitle;
  final String? initialContent;
  final String? initialCategory;
  final int? editIndex;

  const InquiryPostScreen({
    super.key,
    this.initialTitle,
    this.initialContent,
    this.initialCategory,
    this.editIndex
  });

  @override
  State<InquiryPostScreen> createState() => _InquiryPostScreenState();
}


class _InquiryPostScreenState extends State<InquiryPostScreen> {
  String _inquiryType = '문의';
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPrivate = true;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';
    _contentController.text = widget.initialContent ?? '';
    _inquiryType = widget.initialCategory ?? '문의';
  }

  void _submit() {
    if (_isPrivate && _passwordController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호는 4자리여야 합니다.')),
      );
      return;
    }

    final newPost = InquiryData(
      category: _inquiryType,
      title: _titleController.text,
      content: _contentController.text,
      author: '한수연',
      date: DateFormat('yyyy.MM.dd').format(DateTime.now()),
      isPrivate: _isPrivate,
      password: _passwordController.text,
      isAnswered: false,
    );

    Navigator.pop(context, {
      'post': newPost,
      'editIndex': widget.editIndex,
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '문의하기 / 오류 신고',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey.shade300,
            height: 1,
          ),
        ),
      ),

      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // ← 키보드 내림
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabelWithDropdown(),
              const SizedBox(height: 4),
              _buildLabeledTextField('제목', controller: _titleController),
              const SizedBox(height: 4),
              _buildLabeledTextField('내용', controller: _contentController, maxLines: 10),
              Row(
                children: [
                  const Text('비공개', style: TextStyle(fontSize: 14)),
                  Checkbox(
                    value: _isPrivate,
                    activeColor: _isPrivate ? Color(0xFF4262C5) : Colors.white,
                    checkColor: Colors.white, // 체크 아이콘 색상
                    onChanged: (val) => setState(() => _isPrivate = val ?? true),
                  ),
                  const SizedBox(width: 8),
                  const Text('비밀번호', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _roundedBox(
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          border: InputBorder.none,
                          hintText: '',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      backgroundColor: const Color(0xFFEBF0FF),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text('작성', style: TextStyle(fontWeight: FontWeight.bold)),
                  )

              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelWithDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 50,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('유형', style: TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48, // 제목 입력창과 동일한 높이
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: DropdownMenuTheme(
                data: DropdownMenuThemeData(
                  menuStyle: MenuStyle(
                    backgroundColor: WidgetStatePropertyAll(Color(0xFFEBF0FF)),
                    padding: WidgetStatePropertyAll(EdgeInsets.zero),
                    elevation: WidgetStatePropertyAll(2),

                  ),
                ),
                child: DropdownMenu<String>(
                  dropdownMenuEntries: [
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
                        overlayColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.pressed)) {
                            return Colors.grey.withOpacity(0.1);
                          }
                          return Colors.transparent;
                        }),
                      ),
                    ),
                  ],

                  initialSelection: _inquiryType,
                  onSelected: (value) {
                    setState(() {
                      _inquiryType = value!;
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
          ),
        ],
      ),
    );
  }


  Widget _buildLabeledTextField(String label, {required TextEditingController controller, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: maxLines == 1 ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          SizedBox(width: 50, child: Text(label, style: const TextStyle(fontSize: 14))),
          const SizedBox(width: 8),
          Expanded(
            child: _roundedBox(
              TextField(
                controller: controller,
                maxLines: maxLines,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundedBox(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),

      ),
      child: child,
    );
  }
}
