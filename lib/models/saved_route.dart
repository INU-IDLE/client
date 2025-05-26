class SavedRoute {
  final String from;
  final String to;
  final String details;
  final String departureLine;
  final String arrivalLine;

  SavedRoute({
    required this.from,
    required this.to,
    required this.details,
    required this.departureLine,
    required this.arrivalLine,
  });

  @override
  bool operator ==(Object other) {
    return other is SavedRoute &&
        other.from == from &&
        other.to == to &&
        other.details == details;
  }

  @override
  int get hashCode => Object.hash(from, to, details);
}

