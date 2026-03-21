import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:photo_view/photo_view.dart';

import '../models/document.dart';

class DocumentViewerScreen extends StatelessWidget {
  final File documentFile;
  final Document document;

  const DocumentViewerScreen({super.key, required this.documentFile, required this.document});

  @override
  Widget build(BuildContext context) {
    if (document.isPdf) {
      return Scaffold(
        appBar: AppBar(title: Text(document.fileName)),
        body: PDFView(
          filePath: documentFile.path,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
        ),
      );
    }

    if (document.isImage) {
      return Scaffold(
        appBar: AppBar(title: Text(document.fileName)),
        body: PhotoView(
          imageProvider: FileImage(documentFile),
          backgroundDecoration: const BoxDecoration(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(document.fileName)),
      body: Center(
        child: Text('Cannot preview this document type. File is saved at ${documentFile.path}'),
      ),
    );
  }
}
