import 'package:flutter/material.dart';

class ConflictResolverWidget extends StatelessWidget {
  const ConflictResolverWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Conflict Resolver'),
      content: const Text('Conflict resolution UI placeholder.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
      ],
    );
  }
}
