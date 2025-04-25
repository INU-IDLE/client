import 'package:flutter/material.dart';

class NewsHiddenInquiryScreen extends StatefulWidget {
  final void Function(Map<String, String>) onSubmit;
  const NewsHiddenInquiryScreen({super.key, required this.onSubmit});

  @override
  State<NewsHiddenInquiryScreen> createState() => _NewsHiddenInquiryScreenState();
}

class _NewsHiddenInquiryScreenState extends State<NewsHiddenInquiryScreen> {
  String _newsType = '공지';
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  void _submit() {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 모두 입력해주세요.')),
      );
      return;
    }

    final newItem = {
      'type': _newsType,
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      // 'date'는 NewsScreen에서 추가됨
    };

    widget.onSubmit(newItem); // 상위로 전달

    Navigator.pop(context); // 화면 닫기
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
            height: 48,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: DropdownMenuTheme(
                data: DropdownMenuThemeData(
                  menuStyle: MenuStyle(
                    backgroundColor: const WidgetStatePropertyAll(Color(0xFFEBF0FF)),
                    padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                    elevation: const WidgetStatePropertyAll(2),
                  ),
                ),
                child: DropdownMenu<String>(
                  dropdownMenuEntries: [
                    DropdownMenuEntry(
                      value: '공지',
                      label: '공지',
                      style: ButtonStyle(
                        backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
                        overlayColor: WidgetStateProperty.resolveWith((states) => Colors.grey.withOpacity(0.1)),
                      ),
                    ),
                    DropdownMenuEntry(
                      value: '이벤트',
                      label: '이벤트',
                      style: ButtonStyle(
                        backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
                        overlayColor: WidgetStateProperty.resolveWith((states) => Colors.grey.withOpacity(0.1)),
                      ),
                    ),
                    DropdownMenuEntry(
                      value: '패치노트',
                      label: '패치노트',
                      style: ButtonStyle(
                        backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
                        overlayColor: WidgetStateProperty.resolveWith((states) => Colors.grey.withOpacity(0.1)),
                      ),
                    ),
                  ],
                  initialSelection: _newsType,
                  onSelected: (value) => setState(() => _newsType = value!),
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

  Widget _buildLabeledTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: maxLines == 1 ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          SizedBox(width: 50, child: Text(label, style: const TextStyle(fontSize: 14))),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
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
          '소식 관리',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade300, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabelWithDropdown(),
            _buildLabeledTextField('제목', _titleController),
            _buildLabeledTextField('내용', _contentController, maxLines: 10),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
