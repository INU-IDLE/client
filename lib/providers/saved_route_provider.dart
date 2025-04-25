import 'package:flutter/material.dart';
import '../models/saved_route.dart'; // ✅ 이거 반드시 필요!

class SavedRouteProvider extends ChangeNotifier {
  List<SavedRoute> _savedRoutes = [];

  List<SavedRoute> get savedRoutes => _savedRoutes;

  bool isSaved(SavedRoute route) {
    return _savedRoutes.contains(route);
  }

  void toggle(SavedRoute route) {
    if (_savedRoutes.contains(route)) {
      _savedRoutes.remove(route);
    } else {
      _savedRoutes.add(route);
    }
    notifyListeners();
  }

  void removeRoute(SavedRoute route) {
    _savedRoutes.remove(route);
    notifyListeners();
  }
  void updateRoutes(List<SavedRoute> newRoutes) {
    _savedRoutes = List.from(newRoutes);
    notifyListeners();
  }
}