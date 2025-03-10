import 'package:flutter/material.dart';

class StationButton extends StatelessWidget {
  final String stationName;
  final VoidCallback onPressed;

  StationButton({required this.stationName, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.circle, size: 10, color: Colors.white),
      ),
    );
  }
}
