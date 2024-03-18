import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ErrorDialog extends StatelessWidget {
  const ErrorDialog({super.key, required this.error, required this.stackTrace});

  final Object? error;
  final StackTrace stackTrace;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.warning),
      title: const Text('Something Went WRONG: '),
      content: Container(
        constraints:
            const BoxConstraints(maxHeight: 500, minWidth: double.maxFinite),
        child: TextField(
          readOnly: true,
          maxLines: null,
          controller: TextEditingController(
            text: stackTrace.toString(),
          ),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Clipboard.setData(ClipboardData(text: stackTrace.toString())),
          child: const Text('Copy'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        )
      ],
    );
  }
}
