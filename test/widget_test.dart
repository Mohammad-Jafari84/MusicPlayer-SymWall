import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

  import 'package:SymWall/main.dart'; // ایمپورت درست در ابتدای فایل

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // اپلیکیشن را می‌سازیم و اولین فریم را اجرا می‌کنیم
    await tester.pumpWidget(MyApp());

    // بررسی می‌کنیم که مقدار اولیه‌ی شمارنده 0 باشد
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // آیکون '+' را فشار می‌دهیم
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // بررسی می‌کنیم که شمارنده به 1 افزایش یافته باشد
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
