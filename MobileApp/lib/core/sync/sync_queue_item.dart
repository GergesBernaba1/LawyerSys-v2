class SyncQueueItem {
  final String id;
  final String operationType;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> payload;
  final int retryCount;

  SyncQueueItem({required this.id, required this.operationType, required this.entityType, required this.entityId, required this.payload, this.retryCount = 0});

  Map<String, dynamic> toJson() => {
        'id': id,
        'operationType': operationType,
        'entityType': entityType,
        'entityId': entityId,
        'payload': payload,
        'retryCount': retryCount,
      };

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) => SyncQueueItem(
        id: json['id'] as String,
        operationType: json['operationType'] as String,
        entityType: json['entityType'] as String,
        entityId: json['entityId'] as String,
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        retryCount: json['retryCount'] is int ? json['retryCount'] as int : int.tryParse(json['retryCount'].toString()) ?? 0,
      );
}
