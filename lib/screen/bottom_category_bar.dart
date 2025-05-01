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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: MediaQuery.of(context).size.height * 0.04,
                color: isSelected ? const Color(0xFF007AFF) : const Color(0xFF999999),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.03,
                  color: isSelected ? const Color(0xFF007AFF) : const Color(0xFF999999),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.1,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            buildNavItem(Icons.home, "HOME"),
            buildNavItem(Icons.directions_transit, "실시간"),
            buildNavItem(Icons.favorite_border, "저장"),
            buildNavItem(Icons.article, "소식"),
            buildNavItem(Icons.person, "MY"),
          ],
        ),
      ),
    );
  }
}
