import 'package:flutter/material.dart';

void main() => runApp(const DuolingoCloneApp());

class DuolingoCloneApp extends StatelessWidget {
  const DuolingoCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Duolingo Clone - Tim 5',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF58CC02)),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school_rounded, size: 64),
                  SizedBox(height: 20),
                  Text(
                    'Duolingo Clone',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Final Project - Tim 5'),
                  SizedBox(height: 20),
                  Text(
                    'Setup Flutter siap. Fitur belajar akan dikembangkan bersama sesuai README.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
