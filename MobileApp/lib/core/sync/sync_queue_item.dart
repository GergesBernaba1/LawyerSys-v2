class SyncQueueItem {
  final String id;
  final String operationType;
  final Map<String, dynamic> payload;

  SyncQueueItem({required this.id, required this.operationType, required this.payload});

  Map<String, dynamic> toJson() => {
        'id': id,
        'operationType': operationType,
        'payload': payload,
      };

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) => SyncQueueItem(
        id: json['id'] as String,
        operationType: json['operationType'] as String,
        payload: Map<String, dynamic>.from(json['payload'] as Map),
      );
}
