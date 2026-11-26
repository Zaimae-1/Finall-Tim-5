import 'dart:ui' show PointerDeviceKind;

import 'package:duolingo_clone/features/auth/auth_flow.dart';
import 'package:duolingo_clone/features/auth/local_profiles.dart';
import 'package:duolingo_clone/features/learn/learning_home.dart';
import 'package:duolingo_clone/features/learn/learning_progress.dart';
import 'package:duolingo_clone/features/learn/learning_path.dart';
import 'package:duolingo_clone/features/learn/rank.dart';
import 'package:duolingo_clone/features/learn/profile_art.dart';
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
    expect(find.byType(LearningPath), findsOneWidget);
    expect(find.text('Quest harian'), findsNothing);
    expect(find.text('Petualangan Bahasa Inggris'), findsNothing);
    expect(find.text('Ayo selesaikan level 1!'), findsOneWidget);
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
    expect(find.text('100% akurat · +25 XP'), findsOneWidget);
    expect(find.text('+5 Gems'), findsOneWidget);
    expect(find.text('+1 hari streak'), findsOneWidget);
    expect(
      tester.widget<SharkMascot>(find.byType(SharkMascot)).mood,
      SharkMood.celebrate,
    );
    await _tap(tester, 'Kembali ke belajar');
    expect(find.text('Ayo selesaikan level 2!'), findsOneWidget);
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
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Beli · 25 gems'),
          )
          .onPressed,
      isNull,
    );
    expect(find.text('Saldo kamu: 20 gems.'), findsOneWidget);
    final persisted = await ProgressStore('nara@example.com').load();
    expect(persisted.xp, 25);
    expect(persisted.completed, {'greetings'});
    expect(persisted.gems, 20);
    expect(persisted.freezes, 0);
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
    expect(progress.xp, 50);
    expect(progress.freezes, 0);
    expect(progress.lessonsOn(22), 1);
    expect(progress.activeStreak(24), 0);
  });

  test(
    'One hundred levels have playable quizzes and Treasure every fifth stop',
    () {
      expect(lessons.length, 100);
      expect(lessons.map((lesson) => lesson.id).toSet().length, 100);
      for (var index = 0; index < lessons.length; index++) {
        final level = index + 1;
        expect(lessons[index].exercises.length, 5);
        expect(isTreasureLevel(level), level % 5 == 0);
        for (final exercise in lessons[index].exercises) {
          expect(exercise.solution, isNotEmpty);
        }
      }
      expect(
        lessons
            .where((lesson) => lesson.title.startsWith('Pulau harta karun'))
            .length,
        20,
      );
    },
  );

  test('Regular and Treasure rewards are exact and only granted once', () {
    final fifth = lessons[4];
    final first = const LearningProgress().finish(fifth.id, true, 20, level: 5);
    expect(first.xp, 250);
    final repeat = first.finish(fifth.id, true, 20, level: 5);
    expect(repeat.xp, 250);
    expect(LearningProgress.fromJson(repeat.toJson()).xp, 250);
    expect(const LearningProgress().rewardXp(lessons[9].id, false), 250);
    expect(const LearningProgress().rewardXp(lessons[99].id, true), 250);
    expect(const LearningProgress().rewardXp(lessons[98].id, false), 25);
    expect(
      const LearningProgress().rewardXp(lessons[0].id, true, level: 5),
      25,
    );
  });

  test(
    'Gems, streak, boosts, avatars, and skins persist without double rewards',
    () async {
      var progress = const LearningProgress(gems: 100);
      expect(progress.equipAvatar(0), same(progress));
      expect(progress.equipSkin(2), same(progress));
      progress = progress.buyAvatar(0).buySkin(2).buyBoost(10);
      expect(progress.gems, 40);
      expect(progress.avatarId, 0);
      expect(progress.skinId, 2);
      expect(progress.activeBoost, 10);
      expect(progress.boosters[10], 1);
      expect(progress.rewardXp(lessons[0].id, true), 28);
      progress = progress.finish(lessons[0].id, true, 20);
      expect(progress.xp, 28);
      expect(progress.gems, 45);
      expect(progress.streak, 1);
      expect(progress.activeBoost, 0);
      expect(progress.boosters[10], 0);
      progress = progress.finish(lessons[0].id, true, 20);
      expect(progress.xp, 28);
      expect(progress.gems, 45);
      expect(progress.streak, 1);
      progress = progress.finish(lessons[4].id, false, 21);
      expect(progress.xp, 278);
      expect(progress.gems, 60);
      expect(progress.streak, 2);
      expect(progress.activeStreak(23), 0);
      await ProgressStore('items@example.com').save(progress);
      final reloaded = await ProgressStore('items@example.com').load();
      expect(reloaded.xp, 278);
      expect(reloaded.avatarId, 0);
      expect(reloaded.skinId, 2);
      expect(reloaded.ownedAvatars, {0});
      expect(reloaded.ownedSkins, {2});
      expect(reloaded.boosters[10], 0);
      expect(reloaded.buyAvatar(0).gems, 60);
      expect(reloaded.equipAvatar(4), same(reloaded));
    },
  );

  test('All three boosters apply once to regular and Treasure XP', () {
    for (final percent in [5, 7, 10]) {
      final bought = const LearningProgress(gems: 100).buyBoost(percent);
      expect(bought.gems, 100 - LearningProgress.boostPrice(percent));
      expect(
        bought.rewardXp(lessons[0].id, true),
        25 + (25 * percent / 100).round(),
      );
      expect(
        bought.rewardXp(lessons[4].id, true),
        250 + (250 * percent / 100).round(),
      );
      final completed = bought.finish(lessons[4].id, true, 20);
      expect(completed.activeBoost, 0);
      expect(completed.boosters[percent], 0);
      expect(completed.gems, bought.gems + 15);
    }
  });

  test('Rank boundaries and progress follow total XP', () {
    final cases = <int, RankTier>{
      0: RankTier.bronze,
      1: RankTier.bronze,
      29: RankTier.bronze,
      30: RankTier.silver,
      59: RankTier.silver,
      60: RankTier.gold,
      99: RankTier.gold,
      100: RankTier.platinum,
      199: RankTier.platinum,
      200: RankTier.diamond,
      299: RankTier.diamond,
      300: RankTier.ascendant,
      399: RankTier.ascendant,
      400: RankTier.immortal,
      500: RankTier.immortal,
      999: RankTier.immortal,
      1000: RankTier.radiant,
    };
    for (final entry in cases.entries) {
      expect(rankForXp(entry.key), entry.value);
    }
    expect(rankProgress(25), closeTo(25 / 30, .001));
    expect(rankProgress(60), 0);
    expect(rankProgress(1000), 1);
  });

  testWidgets('Profile and leaderboard show XP-based rank badges on phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    _reduceMotion(tester);
    await ProgressStore(
      'rank@example.com',
    ).save(const LearningProgress(xp: 75));
    await tester.pumpWidget(
      MaterialApp(
        theme: lingoSharkTheme(),
        home: LearningHome(
          profile: const LearnerProfile(
            name: 'Kamu',
            email: 'rank@example.com',
          ),
          onSignOut: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final tabs = find.byType(NavigationBar);
    await tester.tap(
      find.descendant(of: tabs, matching: find.byIcon(Icons.person_rounded)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Gold'), findsOneWidget);
    expect(find.text('25 XP lagi menuju Platinum'), findsOneWidget);
    expect(
      tester.widget<RankBadge>(find.byType(RankBadge)).rank,
      RankTier.gold,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Lihat semua rank'));
    await tester.pumpAndSettle();
    expect(find.text('Daftar semua rank'), findsOneWidget);
    final rankScroll = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('400–999 XP'),
      90,
      scrollable: rankScroll,
    );
    await tester.pumpAndSettle();
    expect(find.text('400–999 XP'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('1000+ XP'),
      90,
      scrollable: rankScroll,
    );
    await tester.pumpAndSettle();
    expect(find.text('1000+ XP'), findsOneWidget);
    await _tap(tester, 'Tutup');
    await tester.tap(
      find.descendant(
        of: tabs,
        matching: find.byIcon(Icons.emoji_events_rounded),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(RankBadge), findsNWidgets(9));
    expect(find.text('Radiant'), findsOneWidget);
    expect(find.text('Gold'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Edit profile offers owned art and shop lists five skins', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    _reduceMotion(tester);
    await ProgressStore(
      'avatar@example.com',
    ).save(const LearningProgress(gems: 50).buyAvatar(1));
    await tester.pumpWidget(
      MaterialApp(
        theme: lingoSharkTheme(),
        home: LearningHome(
          profile: const LearnerProfile(
            name: 'Nara',
            email: 'avatar@example.com',
          ),
          onSignOut: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final tabs = find.byType(NavigationBar);
    await tester.tap(
      find.descendant(of: tabs, matching: find.byIcon(Icons.person_rounded)),
    );
    await tester.pumpAndSettle();
    await _tap(tester, 'Edit Profil');
    expect(find.text('Edit profil'), findsOneWidget);
    expect(find.byType(ProfileArt), findsNWidgets(6));
    await tester.tap(
      find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(ProfileArt),
          )
          .at(1),
    );
    await tester.pumpAndSettle();
    expect(find.text('Edit profil'), findsNothing);
    await tester.tap(
      find.descendant(
        of: tabs,
        matching: find.byIcon(Icons.storefront_rounded),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('XP Boosters'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Art profil'),
      220,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    expect(find.text('Art profil'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Skin hiu'),
      220,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    expect(find.text('Skin hiu'), findsOneWidget);
    expect(find.text('Kapten Laut'), findsOneWidget);
    expect(find.text('Pelaut Klasik'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Equipped shark skin appears on the map and in quiz', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    _reduceMotion(tester);
    await ProgressStore(
      'skin@example.com',
    ).save(const LearningProgress(ownedSkins: {2}, skinId: 2));
    await tester.pumpWidget(
      MaterialApp(
        theme: lingoSharkTheme(),
        home: LearningHome(
          profile: const LearnerProfile(
            name: 'Nara',
            email: 'skin@example.com',
          ),
          onSignOut: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final mascot = find.byType(SharkMascot);
    expect(SharkSkinScope.of(tester.element(mascot)), 2);
    await _tap(tester, 'Sapa seseorang');
    await _tap(tester, 'Selamat pagi');
    await _tap(tester, 'Periksa jawaban');
    expect(SharkSkinScope.of(tester.element(find.byType(SharkMascot))), 2);
    expect(tester.takeException(), isNull);
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
    expect(find.text('Sapa seseorang'), findsOneWidget);
    final mapList = find.descendant(
      of: find.byType(LearningPath),
      matching: find.byType(ListView),
    );
    final controller = tester.widget<ListView>(mapList).controller!;
    controller.jumpTo(4 * 220);
    await tester.pump();
    expect(find.text('Pulau harta karun'), findsOneWidget);
    expect(
      tester
          .widget<ListTile>(find.widgetWithText(ListTile, 'Pulau harta karun'))
          .onTap,
      isNull,
    );
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();
    expect(find.text('Pulau harta karun 100'), findsOneWidget);
    expect(find.byType(ListTile).evaluate().length, lessThan(12));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Level 100 unlocks when level 99 is complete', (tester) async {
    _reduceMotion(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LearningPath(
            lessons: lessons,
            completed: {for (final lesson in lessons.take(99)) lesson.id},
            animate: false,
            onOpen: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final mapList = find.descendant(
      of: find.byType(LearningPath),
      matching: find.byType(ListView),
    );
    final controller = tester.widget<ListView>(mapList).controller!;
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();
    expect(
      tester
          .widget<ListTile>(
            find.widgetWithText(ListTile, 'Pulau harta karun 100'),
          )
          .onTap,
      isNotNull,
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
