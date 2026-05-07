class RecentActivity {

  RecentActivity({required this.id, required this.title, required this.description, required this.timestamp});

  factory RecentActivity.fromJson(Map<String, dynamic> json) => RecentActivity(
    id: (json['id'] as String?) ?? '',
    title: (json['title'] as String?) ?? '',
    description: (json['description'] as String?) ?? '',
    timestamp: DateTime.parse((json['timestamp'] as String?) ?? DateTime.now().toIso8601String()),
  );
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
  };
}
