import 'dart:async';

import 'package:flutter/material.dart';

class ErrorCard extends StatelessWidget {
  final String message;
  final String buttonText;
  final Completer<void>? completer;
  const ErrorCard({Key? key, required this.message, required this.buttonText, required this.completer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    TextStyle onErrorStyle = TextStyle(color: colorScheme.onErrorContainer);

    return Column(
      children: [
        Card(
            color: colorScheme.errorContainer,
            child: ListTile(
              title: Text(message, style: onErrorStyle),
              trailing: TextButton(
                onPressed: completer?.complete,
                child: Text(buttonText, style: onErrorStyle),
              ),
            )),
        const SizedBox(height: 8)
      ],
    );
  }
}
