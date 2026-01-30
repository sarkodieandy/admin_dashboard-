// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:finger_licking_customer/core/app.dart';
import 'package:finger_licking_customer/core/constants/app_strings.dart';

void main() {
  testWidgets('shows Supabase setup when missing env', (WidgetTester tester) async {
    await tester.pumpWidget(const App(isSupabaseConfigured: false));

    expect(find.text(AppStrings.supabaseMissingTitle), findsOneWidget);
    expect(find.textContaining('--dart-define=SUPABASE_URL'), findsOneWidget);
  });
}
