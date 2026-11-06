import 'package:flutter_test/flutter_test.dart';
import 'package:mid/app.dart';

void main() {
  testWidgets('Login page opens', (tester) async {
    await tester.pumpWidget(const MidApp());
    expect(find.text('Tizimga kirish'), findsOneWidget);
    expect(find.text('Kirish'), findsOneWidget);
  });
}
