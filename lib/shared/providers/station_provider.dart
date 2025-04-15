import 'package:flutter/cupertino.dart';

class StationProvider with ChangeNotifier {
  String? _departureStation;
  String? _arrivalStation;
  String? _searchedStation;

  // --- Getter ---
  String? get departureStation => _departureStation;
  String? get arrivalStation => _arrivalStation;
  String? get searchedStation => _searchedStation;

  // --- 검색 후 임시 저장 ---
  void setSearchedStation(String station) {
    _searchedStation = station;
    notifyListeners();
  }

  // --- 출발/도착역에 임시 저장값 적용 ---
  void applySearchedToDeparture() {
    if (_searchedStation?.isNotEmpty ?? false) {
      _departureStation = _searchedStation;
      _searchedStation = null;
      notifyListeners();
    }
  }

  void applySearchedToArrival() {
    if (_searchedStation?.isNotEmpty ?? false) {
      _arrivalStation = _searchedStation;
      _searchedStation = null;
      notifyListeners();
    }
  }

  // --- 직접 출발/도착역 설정 (예외적 상황용) ---
  void setDepartureStation(String station) {
    if (station != _departureStation) {
      _departureStation = station;
      notifyListeners();
    }
  }

  void setArrivalStation(String station) {
    if (station != _arrivalStation) {
      _arrivalStation = station;
      notifyListeners();
    }
  }

  // --- 출발/도착역 교환 ---
  void swapStations() {
    if (_departureStation != null && _arrivalStation != null) {
      final temp = _departureStation;
      _departureStation = _arrivalStation;
      _arrivalStation = temp;
      notifyListeners();
    }
  }

  // --- 모든 역 초기화 ---
  void clearStations() {
    _departureStation = null;
    _arrivalStation = null;
    _searchedStation = null;
    notifyListeners();
  }
}
