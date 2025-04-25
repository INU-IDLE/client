class SavedRoute {
  final String from;
  final String to;
  final String details;

  SavedRoute({
    required this.from,
    required this.to,
    required this.details,
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