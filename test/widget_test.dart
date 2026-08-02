import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getwork/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GetWorkApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
