import 'package:bus/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('first launch shows Birmingham Buses and default route 16',
      (tester) async {
    await tester.pumpWidget(const BirminghamBusesApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Birmingham Buses'), findsOneWidget);
    expect(find.textContaining('Route 16'), findsWidgets);
  });
}
