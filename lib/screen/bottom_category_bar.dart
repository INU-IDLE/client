import 'package:flutter/cupertino.dart';
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
    Widget buildNavItem(IconData icon, String label) {
      final isSelected = selectedCategory == label;
      return Expanded(
        child: GestureDetector(
          onTap: () => onCategorySelected(label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0x19007AFF) : Colors.transparent, // 선택시 연한 블루 배경
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: isSelected ? const Color(0xFF007AFF) : const Color(0xFF8E8E93),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? const Color(0xFF007AFF) : const Color(0xFF8E8E93),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 62,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, -2))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            buildNavItem(CupertinoIcons.home, "HOME"),
            buildNavItem(CupertinoIcons.bus, "실시간"),
            buildNavItem(CupertinoIcons.heart, "저장"),
            buildNavItem(CupertinoIcons.news, "소식"),
            buildNavItem(CupertinoIcons.person, "MY"),

          ],
        ),
      ),
    );
  }
}
