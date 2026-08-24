// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/material.dart';
import 'package:mobile/services/update_service.dart';
import 'package:mobile/ui/widgets/update_dialog.dart';

void main() {
  testWidgets('UpdateDialog renders optional update correctly', (WidgetTester tester) async {
    const update = AppUpdateInfo(
      hasUpdate: true,
      isForced: false,
      latestVersion: '1.2.0',
      minVersion: '1.0.0',
      currentVersion: '1.0.0',
      downloadUrl: 'https://example.com/app.apk',
      changelog: '• Improved offline stability',
      title: 'New Update Available',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: UpdateDialog(update: update),
        ),
      ),
    );

    expect(find.text('New Update Available'), findsOneWidget);
    expect(find.text('v1.0.0'), findsOneWidget);
    expect(find.text('v1.2.0'), findsOneWidget);
    expect(find.text('• Improved offline stability'), findsOneWidget);
    expect(find.text('Update Now'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
  });

  testWidgets('UpdateDialog renders enforced update correctly', (WidgetTester tester) async {
    const update = AppUpdateInfo(
      hasUpdate: true,
      isForced: true,
      latestVersion: '2.0.0',
      minVersion: '2.0.0',
      currentVersion: '1.0.0',
      downloadUrl: 'https://example.com/app.apk',
      changelog: '• Mandatory security updates',
      title: 'Important Update Required',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: UpdateDialog(update: update),
        ),
      ),
    );

    expect(find.text('Important Update Required'), findsOneWidget);
    expect(find.text('Update Now (Required)'), findsOneWidget);
    expect(find.text('Later'), findsNothing); // Forced update does not have "Later"
  });
}
