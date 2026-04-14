import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Proje isminin 'myteammate' olduğunu varsayıyorum
import 'package:myteammate/pages/login_page.dart';

void main() {
  testWidgets('Login page smoke test', (WidgetTester tester) async {
    // Uygulamayı LoginPage ile başlatıyoruz
    // LoginPage'i bir MaterialApp içine koymamız gerekir çünkü
    // Scaffold veya TextField gibi widget'lar MaterialApp context'ine ihtiyaç duyar.
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    // Not: Varsayılan sayaç testi kodlarını sildim çünkü
    // giriş sayfasında muhtemelen '0' sayısı veya '+' butonu yoktur.
    // Bunun yerine sayfanın yüklendiğini kontrol edelim:

    // Örnek: Eğer login sayfasında "Giriş" yazısı varsa:
    // expect(find.text('Giriş'), findsOneWidget);
  });
}
