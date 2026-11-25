import 'package:duolingo_clone/features/auth/local_profiles.dart';
import 'package:duolingo_clone/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('Small screen form validates inputs and switches mode', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const DuolingoCloneApp());

    final register = find.widgetWithText(FilledButton, 'Buat akun');
    await tester.ensureVisible(register);
    await tester.tap(register);
    await tester.pumpAndSettle();

    await tester.ensureVisible(register);
    await tester.tap(register);
    await tester.pumpAndSettle();
    expect(find.text('Masukkan email yang valid.'), findsOneWidget);
    expect(find.text('Masukkan nama panggilan.'), findsOneWidget);

    final password = find.byKey(const ValueKey('auth-password'));
    await tester.enterText(password, 'latihan123');
    final toggle = find.byTooltip('Tampilkan kata sandi');
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Sembunyikan kata sandi'), findsOneWidget);

    final switchMode = find.text('Sudah punya akun? Masuk');
    await tester.ensureVisible(switchMode);
    await tester.tap(switchMode);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('auth-name')), findsNothing);
    expect(find.text('Masuk lagi'), findsOneWidget);
    expect(tester.widget<TextFormField>(password).controller!.text, isEmpty);
    expect(tester.takeException(), isNull);
  });

  test(
    'Demo account can be reloaded and rejects invalid credentials',
    () async {
      final profiles = LocalProfiles();
      final created = await profiles.register(
        name: 'Nara',
        email: 'NARA@example.com',
        password: 'latihan123',
      );
      expect(created?.name, 'Nara');
      expect(created?.email, 'nara@example.com');
      expect(
        await profiles.register(
          name: 'Lain',
          email: 'nara@example.com',
          password: 'different123',
        ),
        isNull,
      );

      final reopened = LocalProfiles();
      expect(
        await reopened.signIn(email: 'nara@example.com', password: 'salah123'),
        isNull,
      );
      final signedIn = await reopened.signIn(
        email: ' nara@example.com ',
        password: 'latihan123',
      );
      expect(signedIn?.name, 'Nara');
    },
  );
}
