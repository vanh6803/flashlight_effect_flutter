import 'package:flash_test/flash_control_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flash Control',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TorchController(),
    );
  }
}
