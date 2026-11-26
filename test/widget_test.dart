import 'dart:ui' show PointerDeviceKind;

import 'package:duolingo_clone/features/auth/auth_flow.dart';
import 'package:duolingo_clone/features/auth/local_profiles.dart';
import 'package:duolingo_clone/features/learn/learning_home.dart';
import 'package:duolingo_clone/features/learn/learning_progress.dart';
import 'package:duolingo_clone/features/learn/learning_path.dart';
import 'package:duolingo_clone/features/learn/course.dart';
import 'package:duolingo_clone/features/learn/learning_tab_bar.dart';
import 'package:duolingo_clone/main.dart';
import 'package:duolingo_clone/shared/shark_mascot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('Small screen setup leads to form validation and sign-in', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    _reduceMotion(tester);
    await tester.pumpWidget(const DuolingoCloneApp());

    await _tap(tester, 'Mulai belajar');
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Lanjut'))
          .onPressed,
      isNull,
    );
    await _tap(tester, 'Pemula');
    await _tap(tester, 'Lanjut');
    await _tap(tester, '1 lesson per hari');
    await _tap(tester, 'Lanjut');
    await _tap(tester, 'Buat akun');
    expect(find.text('Masukkan email yang valid.'), findsOneWidget);
    expect(find.text('Masukkan nama panggilan.'), findsOneWidget);

    final password = find.byKey(const ValueKey('auth-password'));
    await tester.enterText(password, 'latihan123');
    final toggle = find.byTooltip('Tampilkan kata sandi');
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Sembunyikan kata sandi'), findsOneWidget);

    await _tap(tester, 'Sudah punya akun? Masuk');
    expect(find.byKey(const ValueKey('auth-name')), findsNothing);
    expect(find.text('Masuk lagi'), findsOneWidget);
    expect(tester.widget<TextFormField>(password).controller!.text, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('The shark moves and respects reduced motion', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: SharkMascot(size: 120))),
      ),
    );
    final transform = find
        .descendant(
          of: find.byType(SharkMascot),
          matching: find.byType(Transform),
        )
        .first;
    await tester.pump();
    final still = tester.widget<Transform>(transform).transform.clone();
    await tester.pump(const Duration(milliseconds: 1200));
    expect(tester.widget<Transform>(transform).transform, isNot(still));

    _reduceMotion(tester);
    await tester.pumpAndSettle();
    expect(tester.widget<Transform>(transform).transform, still);
  });

  testWidgets('A short banner keeps the shark pose square and centered', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 220,
              height: 136,
              child: SharkMascot(size: 200, animate: false),
            ),
          ),
        ),
      ),
    );
    final mascot = find.byType(SharkMascot);
    final pose = find
        .descendant(of: mascot, matching: find.byType(Transform))
        .first;
    expect(tester.getSize(pose), const Size.square(136));
    expect(tester.getCenter(pose), tester.getCenter(mascot));
  });

  testWidgets('A full lesson unlocks the next stop and funds a quest reward', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    _reduceMotion(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: lingoSharkTheme(),
        home: LearningHome(
          profile: const LearnerProfile(
            name: 'Nara',
            email: 'nara@example.com',
          ),
          onSignOut: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Jalur belajar'), findsOneWidget);
    expect(
      tester
          .widget<ListTile>(find.widgetWithText(ListTile, 'Perkenalkan diri'))
          .onTap,
      isNull,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -430));
    await tester.pumpAndSettle();
    await _tap(tester, 'Sapa seseorang');

    for (final answers in [
      ['Selamat pagi'],
      ['How', 'are', 'you'],
      ['Hello', 'Halo', 'Thanks', 'Terima kasih', 'Goodbye', 'Sampai jumpa'],
      ['Nice to meet you'],
      ['See', 'you', 'tomorrow'],
    ]) {
      for (final answer in answers) {
        await _tap(tester, answer);
      }
      await _tap(tester, 'Periksa jawaban');
      expect(find.text('Tepat sekali!'), findsOneWidget);
      expect(
        tester.widget<SharkMascot>(find.byType(SharkMascot)).mood,
        SharkMood.correct,
      );
      await _tap(tester, 'Lanjut');
    }
    expect(find.text('100% akurat · +15 XP'), findsOneWidget);
    expect(
      tester.widget<SharkMascot>(find.byType(SharkMascot)).mood,
      SharkMood.celebrate,
    );
    await _tap(tester, 'Kembali ke belajar');
    expect(
      tester
          .widget<ListTile>(find.widgetWithText(ListTile, 'Perkenalkan diri'))
          .onTap,
      isNotNull,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.flag_rounded),
      ),
    );
    await tester.pumpAndSettle();
    await _tap(tester, 'Klaim hadiah');
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Sudah diklaim'),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.storefront_rounded),
      ),
    );
    await tester.pumpAndSettle();
    await _tap(tester, 'Beli · 25 gems');
    expect(find.text('Saldo kamu: 0 gems.'), findsOneWidget);
    final persisted = await ProgressStore('nara@example.com').load();
    expect(persisted.xp, 15);
    expect(persisted.completed, {'greetings'});
    expect(persisted.freezes, 1);
    expect(tester.takeException(), isNull);
  });

  test(
    'Demo account reload preserves setup and rejects invalid credentials',
    () async {
      final profiles = LocalProfiles();
      final created = await profiles.register(
        name: 'Nara',
        email: 'NARA@example.com',
        password: 'latihan123',
        dailyGoal: 2,
        level: 'Sudah tahu sedikit',
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
      expect(signedIn?.dailyGoal, 2);
      expect(signedIn?.level, 'Sudah tahu sedikit');
    },
  );

  testWidgets(
    'Bottom tabs work on desktop and leave room to scroll on phones',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      _reduceMotion(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: lingoSharkTheme(),
          home: LearningHome(
            profile: const LearnerProfile(
              name: 'Nara',
              email: 'nara@example.com',
            ),
            onSignOut: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tabs = find.byType(NavigationBar);
      expect(tester.getRect(tabs).bottom, greaterThan(760));
      expect(tester.getCenter(tabs).dx, closeTo(640, 1));
      expect(
        find.descendant(of: tabs, matching: find.byType(NavigationDestination)),
        findsNWidgets(5),
      );

      await tester.tap(
        find.descendant(of: tabs, matching: find.byIcon(Icons.person_rounded)),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<NavigationBar>(tabs).selectedIndex, 4);
      expect(find.text('Profil pelajar'), findsOneWidget);

      await tester.binding.setSurfaceSize(const Size(320, 568));
      await tester.pumpAndSettle();
      final signOut = find.widgetWithText(OutlinedButton, 'Keluar');
      await tester.scrollUntilVisible(
        signOut,
        140,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getRect(signOut).bottom,
        lessThan(tester.getRect(tabs).top),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Hover glides between tabs and fades without selecting a tab', (
    tester,
  ) async {
    int? selection;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: LearningTabBar(
            selectedIndex: 0,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.explore),
                label: 'Belajar',
              ),
              NavigationDestination(icon: Icon(Icons.flag), label: 'Quest'),
              NavigationDestination(icon: Icon(Icons.store), label: 'Toko'),
            ],
            onSelected: (index) => selection = index,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final quest = tester.getCenter(find.text('Quest'));
    final shop = tester.getCenter(find.text('Toko'));
    final hover = find.byKey(const ValueKey('learning-tab-hover'));
    final pill = find.descendant(
      of: hover,
      matching: find.byType(DecoratedBox),
    );
    final fade = find.descendant(
      of: hover,
      matching: find.byType(FadeTransition),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);

    await mouse.addPointer(location: quest);
    await tester.pumpAndSettle();
    expect(tester.getCenter(pill).dx, closeTo(quest.dx, 1));
    expect(tester.widget<FadeTransition>(fade).opacity.value, 1);

    await mouse.moveTo(shop);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 55));
    expect(tester.getCenter(pill).dx, inExclusiveRange(quest.dx, shop.dx));
    await tester.pumpAndSettle();
    expect(tester.getCenter(pill).dx, closeTo(shop.dx, 1));
    expect(selection, isNull);

    await mouse.moveTo(const Offset(5, 5));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 55));
    expect(
      tester.widget<FadeTransition>(fade).opacity.value,
      inExclusiveRange(0, 1),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<FadeTransition>(fade).opacity.value, 0);
    await mouse.removePointer();

    await tester.tap(find.text('Toko'));
    expect(selection, 2);
  });

  test('Repeat practice preserves XP and a freeze covers one missed day', () {
    final progress = const LearningProgress(freezes: 1)
        .finish('greetings', true, 20)
        .finish('greetings', true, 20)
        .finish('intro', false, 22);
    expect(progress.streak, 2);
    expect(progress.xp, 25);
    expect(progress.freezes, 0);
    expect(progress.lessonsOn(22), 1);
    expect(progress.activeStreak(24), 0);
  });

  test('Treasure island grants 250 bonus XP only on first completion', () {
    expect(lessons.length, greaterThanOrEqualTo(5));
    final fifth = lessons[4];
    final first = const LearningProgress().finish(fifth.id, true, 20, level: 5);
    expect(first.xp, 265);
    final repeat = first.finish(fifth.id, true, 20, level: 5);
    expect(repeat.xp, 265);
    expect(LearningProgress.fromJson(repeat.toJson()).xp, 265);
    expect(const LearningProgress().rewardXp('future', false, level: 10), 260);
  });

  testWidgets('The sea map rises from boat level 1 to island level 5', (
    tester,
  ) async {
    _reduceMotion(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LearningPath(
            lessons: lessons,
            completed: const {},
            animate: true,
            onOpen: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Peta petualangan'), findsOneWidget);
    expect(find.bySemanticsLabel('Kapal level 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Pulau harta karun level 5'), findsOneWidget);
    expect(
      tester
          .widget<ListTile>(find.widgetWithText(ListTile, 'Pulau harta karun'))
          .onTap,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}

void _reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Future<void> _tap(WidgetTester tester, String label) async {
  final target = find.text(label);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}
