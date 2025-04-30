import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/station.dart';

class StationMapPainter extends CustomPainter {
  final List<Station> stations;
  final String? selectedStationId;

  StationMapPainter(this.stations, this.selectedStationId);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    for (var station in stations) {
      canvas.drawCircle(Offset(station.cx, station.cy), 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}