import "package:flutter/material.dart";

class TextDisplay extends StatefulWidget {
  const TextDisplay({super.key, required this.text});

  final String? text;

  @override
  State<TextDisplay> createState() => _TextDisplayState();
}

class _TextDisplayState extends State<TextDisplay> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(),
    body: Text(widget.text!));
  }
}

