import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('SplashScreen loads and transitions to LoginScreen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    // Build app with SplashScreen
    await tester.pumpWidget(const MyApp());

    // Verify splash screen displays app branding
    expect(find.textContaining('Phone Parts'), findsWidgets);

    // Advance splash screen timer (2200ms)
    await tester.pump(const Duration(milliseconds: 2200));

    // Allow SharedPreferences async futures to resolve
    await tester.idle();

    // Pump transition frame
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    // Verify that LoginScreen welcome text is displayed
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Customer Signup'), findsOneWidget);
    expect(find.text('Vendor Signup'), findsOneWidget);
  });
}
