import 'package:flutter/material.dart';
import '../models/court.dart';

class CourtFormScreen extends StatelessWidget {
  final CourtModel? court;
  const CourtFormScreen({super.key, this.court});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(court == null ? 'Add Court' : 'Edit Court')),
      body: const Center(child: Text('Court form coming soon')),
    );
  }
}
