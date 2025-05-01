import 'dart:math';
import 'package:flutter/material.dart';
import 'package:rushcutter/models/station.dart';

class StationComponent extends StatefulWidget{
  final List<Station> stations;
  final String? selectedId;
  final void Function(String? id) onStationTap; // null 허용

  const StationComponent({
    required this.stations,
    required this.selectedId,
    required this.onStationTap,
    super.key,
  });

  @override
  State<StationComponent> createState() => _StationComponentState();
}

class _StationComponentState extends State<StationComponent> {
  Offset? _tapPosition;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        _tapPosition = details.localPosition;
      },
      onTap: () {
        if (_tapPosition == null) return;

        bool stationTapped = false;
        for (final station in widget.stations) {
          final dx = _tapPosition!.dx - station.cx;
          final dy = _tapPosition!.dy - station.cy;
          final distance = sqrt(dx * dx + dy * dy);
          if (distance <= station.r) {
            widget.onStationTap(station.id); // 역 선택
            stationTapped = true;
            break;
          }
        }
        if (!stationTapped) {
          widget.onStationTap(null); // 배경 클릭 시 선택 해제
        }
        _tapPosition = null;
      },
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        size: const Size(4500, 3800),
        painter: StationMapPainter(widget.stations, widget.selectedId),
      ),
    );
  }
}

class StationMapPainter extends CustomPainter {
  final List<Station> stations;
  final String? selectedId;

  StationMapPainter(this.stations, this.selectedId);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.blue.withOpacity(0.4);

    for (final station in stations) {
      canvas.drawCircle(Offset(station.cx, station.cy), station.r, paint);
    }

    if (selectedId != null) {
      final station = stations.firstWhere((s) => s.id == selectedId, orElse: () => stations.first);
      final textPainter = TextPainter(
        text: TextSpan(
          text: station.stationNm,
          style: const TextStyle(color: Colors.black, fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(station.cx + 10, station.cy));
    }
  }

  @override
  bool shouldRepaint(covariant StationMapPainter oldDelegate) {
    return oldDelegate.selectedId != selectedId || oldDelegate.stations != stations;
  }
}