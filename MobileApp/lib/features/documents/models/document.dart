import '../../../core/api/api_constants.dart';

class Document {
  final int id;
  final String code;
  final String path;
  final bool type;

  Document(
      {required this.id,
      required this.code,
      required this.path,
      required this.type});

  String get fileName => path.split('/').last;

  String get downloadUrl => '${ApiConstants.baseUrl}/files/$id/download';

  String get viewUrl => '${ApiConstants.baseUrl}/files/$id/view';

  bool get isPdf => path.toLowerCase().endsWith('.pdf');
  bool get isImage =>
      path.toLowerCase().contains('.png') ||
      path.toLowerCase().contains('.jpg') ||
      path.toLowerCase().contains('.jpeg') ||
      path.toLowerCase().contains('.gif') ||
      path.toLowerCase().contains('.bmp') ||
      path.toLowerCase().contains('.webp');

  factory Document.fromJson(Map<String, dynamic> json) => Document(
        id: json['id'] as int,
        code: json['code'] as String? ?? '',
        path: json['path'] as String? ?? '',
        type: json['type'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'path': path,
        'type': type,
      };
}
