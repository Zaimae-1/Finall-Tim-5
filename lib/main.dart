import 'package:flutter/material.dart';

import 'features/auth/auth_flow.dart';

void main() => runApp(const DuolingoCloneApp());

class DuolingoCloneApp extends StatelessWidget {
  const DuolingoCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LingoShark',
      debugShowCheckedModeBanner: false,
      theme: lingoSharkTheme(),
      home: const AuthFlow(),
    );
  }
}
