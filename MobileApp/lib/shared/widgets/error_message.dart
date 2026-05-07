import 'package:flutter/material.dart';

class ErrorMessage extends StatelessWidget {

  const ErrorMessage(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(message, style: const TextStyle(color: Colors.red));
  }
}
