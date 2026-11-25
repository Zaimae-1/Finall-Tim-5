import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duolingo_clone/main.dart';

void main() {
  testWidgets('Starter app opens successfully', (tester) async {
    await tester.pumpWidget(const DuolingoCloneApp());
    expect(find.text('Duolingo Clone'), findsOneWidget);
    expect(find.text('Final Project - Tim 5'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
