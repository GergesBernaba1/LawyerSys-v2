class RecentActivity {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;

  RecentActivity({required this.id, required this.title, required this.description, required this.timestamp});

  factory RecentActivity.fromJson(Map<String, dynamic> json) => RecentActivity(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
  };
}
