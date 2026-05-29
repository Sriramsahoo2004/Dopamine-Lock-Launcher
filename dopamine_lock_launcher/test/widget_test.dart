import 'package:dopamine_lock_launcher/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders launcher shell', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('DopamineLock'), findsOneWidget);
  });
}
