import 'package:flutter/material.dart';

class BottomCategoryBar extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const BottomCategoryBar({
    Key? key,
    required this.selectedCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'icon': Icons.home, 'label': 'HOME'},
      {'icon': Icons.timer, 'label': '실시간'},
      {'icon': Icons.save, 'label': '저장'},
      {'icon': Icons.newspaper, 'label': '소식'},
      {'icon': Icons.person, 'label': '마이페이지'},
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.1,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: categories.map((category) {
          final isSelected = selectedCategory == category['label'];
          return GestureDetector(
            onTap: () => onCategorySelected(category['label'] as String),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  category['icon'] as IconData,
                  size: MediaQuery.of(context).size.height * 0.04,
                  color:
                  isSelected ? const Color(0xFF007AFF) : const Color(0xFF999999),
                ),
                const SizedBox(height: 4),
                Text(
                  category['label'] as String,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.03,
                    color:
                    isSelected ? const Color(0xFF007AFF) : const Color(0xFF999999),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
