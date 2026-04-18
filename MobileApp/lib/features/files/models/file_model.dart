class FileModel {
  final String id;
  final String title;
  final String? description;
  final String? category;
  final String? fileExtension;
  final String? mimeType;
  final int? fileSize;
  final DateTime createdAt;
  final String? createdBy;

  FileModel({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.fileExtension,
    this.mimeType,
    this.fileSize,
    required this.createdAt,
    this.createdBy,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      category: json['category']?.toString(),
      fileExtension: json['fileExtension']?.toString(),
      mimeType: json['mimeType']?.toString(),
      fileSize: json['fileSize'] is int
          ? json['fileSize'] as int
          : int.tryParse(json['fileSize']?.toString() ?? ''),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      createdBy: json['createdBy']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'fileExtension': fileExtension,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  /// Returns a human-readable file size string (e.g. "1.2 MB")
  String get formattedSize {
    if (fileSize == null) return '';
    final kb = fileSize! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Returns the extension in lowercase without the leading dot
  String get normalizedExtension {
    final ext = fileExtension ?? '';
    return ext.startsWith('.') ? ext.substring(1).toLowerCase() : ext.toLowerCase();
  }
}
