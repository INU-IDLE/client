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
      {'icon': Icons.home_outlined, 'label': 'HOME'},
      {'icon': Icons.train, 'label': '실시간'},
      {'icon': Icons.star_outline, 'label': '저장'},
      {'icon': Icons.article_outlined, 'label': '소식'},
      {'icon': Icons.person_outline, 'label': '마이페이지'},
    ];

    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12), // ✅ 좌측 여백 (적당한 값으로 조절)
          ...categories.map((category) {
            final isSelected = selectedCategory == category['label'];
            return Expanded(
              child: GestureDetector(
                onTap: () => onCategorySelected(category['label'] as String),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      size: 26,
                      color: isSelected ? const Color(0xFF007AFF) : const Color(0xFF999999),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? const Color(0xFF007AFF) : const Color(0xFF999999),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          const SizedBox(width: 12), // ✅ 우측 여백
        ],
      ),
    );
  }
}
