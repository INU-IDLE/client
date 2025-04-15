import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

// 역 정보 관리 Station class
class Station {
  final String id; // station_positions.json id
  final double cx;
  final double cy;
  final double r;
  final String stationNm; // station_info.json
  final String line;

  Station({
    required this.id,
    required this.cx,
    required this.cy,
    required this.r,
    required this.stationNm,
    required this.line,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'].toString(),
      cx: (json['cx'] as num?)?.toDouble() ?? 0.0,
      cy: (json['cy'] as num?)?.toDouble() ?? 0.0,
      r: json['r'].toDouble(),
      stationNm: json['station_nm'],
      line: json['line'],
    );
  }
}