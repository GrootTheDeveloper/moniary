import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moniary/app/app.dart';

void main() {
  testWidgets('App boots into the stage 0 flow', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MoniaryApp(),
      ),
    );

    expect(find.text('Moniary'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Ghi chi tieu bang anh.'), findsOneWidget);
    expect(find.text('Di toi Calendar placeholder'), findsOneWidget);
  });
}
