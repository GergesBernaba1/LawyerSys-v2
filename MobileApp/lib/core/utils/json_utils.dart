List<dynamic> normalizeJsonList(dynamic raw) {
  if (raw is List<dynamic>) return raw;
  if (raw is Map<String, dynamic>) {
    final items = raw['items'] ?? raw['Items'];
    if (items is List<dynamic>) return items;
  }
  return const [];
}
