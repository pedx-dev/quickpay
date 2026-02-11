// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laod/main.dart';
import 'package:laod/services/hive_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await HiveService.init();
  });

  testWidgets('QuickPay wallet app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WalletApp());
    await tester.pumpAndSettle();

    // Verify that the app loads with QuickPay text
    expect(find.text('QuickPay'), findsAtLeastNWidgets(1));
  });
}
