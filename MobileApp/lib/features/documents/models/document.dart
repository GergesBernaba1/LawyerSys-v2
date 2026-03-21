class Document {
  final String documentId;
  final String fileName;

  Document({required this.documentId, required this.fileName});

  factory Document.fromJson(Map<String, dynamic> json) => Document(
        documentId: json['documentId'] as String,
        fileName: json['fileName'] as String,
      );

  Map<String, dynamic> toJson() => {
        'documentId': documentId,
        'fileName': fileName,
      };
}
