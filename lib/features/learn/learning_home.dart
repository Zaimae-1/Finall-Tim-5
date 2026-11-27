import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/motion.dart';
import '../../shared/shark_mascot.dart';
import '../auth/local_profiles.dart';
import 'boost_countdown.dart';
import 'course.dart';
import 'learning_progress.dart';
import 'learning_path.dart';
import 'learning_tab_bar.dart';
import 'lesson_page.dart';
import 'profile_art.dart';
import 'rank.dart';
import 'rank_list_sheet.dart';
import 'rank_presentation.dart';

const _navy = Color(0xFF103552);
const _blue = Color(0xFF075DAB);
const _muted = Color(0xFF47647A);
const _outline = Color(0xFFD8E6F0);
const _ice = Color(0xFFE5F3FF);

enum _Destination {
  learn('Belajar', Icons.explore_rounded),
  quests('Quest', Icons.flag_rounded),
  ranks('Peringkat', Icons.emoji_events_rounded),
  shop('Toko', Icons.storefront_rounded),
  profile('Profil', Icons.person_rounded);

  const _Destination(this.label, this.icon);
  final String label;
  final IconData icon;
}

class LearningHome extends StatefulWidget {
  const LearningHome({
    super.key,
    required this.profile,
    required this.onSignOut,
  });

  final LearnerProfile profile;
  final VoidCallback onSignOut;

  @override
  State<LearningHome> createState() => _LearningHomeState();
}

class _LearningHomeState extends State<LearningHome> {
  late final _store = ProgressStore(widget.profile.email);
  late var _loading = _store.load();
  LearningProgress? _progress;
  var _tab = _Destination.learn;
  bool _saving = false;
  bool _lessonOpen = false;
  String? _recentlyCompleted;
  Timer? _dayRefresh;

  @override
  void initState() {
    super.initState();
    _scheduleDayRefresh();
  }

  void _scheduleDayRefresh() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    _dayRefresh = Timer(
      midnight.difference(now) + const Duration(milliseconds: 100),
      () {
        if (!mounted) return;
        setState(() {});
        _scheduleDayRefresh();
      },
    );
  }

  @override
  void dispose() {
    _dayRefresh?.cancel();
    super.dispose();
  }

  Future<void> _save(LearningProgress next) async {
    setState(() => _saving = true);
    try {
      await _store.save(next);
      if (mounted) setState(() => _progress = next);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _update(LearningProgress next, {String? message}) async {
    if (_saving) return;
    try {
      await _save(next);
      if (message != null && mounted) _message(message);
    } on Exception {
      if (mounted) _message('Perubahan gagal disimpan. Coba lagi.');
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openLesson(Lesson lesson, LearningProgress progress) async {
    if (_lessonOpen || _saving) return;
    _lessonOpen = true;
    ({RankTier from, RankTier to})? promotion;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => SharkSkinScope(
            skinId: (_progress ?? progress).skinId,
            child: LessonPage(
              lesson: lesson,
              animateMascot: progress.motion,
              onComplete: (perfect) async {
                final current = _progress ?? progress;
                final level =
                    lessons.indexWhere((entry) => entry.id == lesson.id) + 1;
                final day = localDay(DateTime.now());
                final next = current.finish(
                  lesson.id,
                  perfect,
                  day,
                  level: level,
                );
                await _save(next);
                final previousRank = rankForXp(current.xp);
                final newRank = rankForXp(next.xp);
                if (next.xp > current.xp &&
                    newRank.index > previousRank.index) {
                  promotion = (from: previousRank, to: newRank);
                }
                return (
                  xp: next.xp - current.xp,
                  gems: next.gems - current.gems,
                  streak: next.activeStreak(day) - current.activeStreak(day),
                );
              },
            ),
          ),
        ),
      );
      if (mounted &&
          !progress.completed.contains(lesson.id) &&
          _progress?.completed.contains(lesson.id) == true) {
        setState(() => _recentlyCompleted = lesson.id);
      }
      if (mounted && promotion != null) {
        final promoted = promotion!;
        await showDialog<void>(
          context: context,
          builder: (context) => RankUpDialog(
            from: promoted.from,
            to: promoted.to,
            animate: (_progress ?? progress).motion,
          ),
        );
      }
    } finally {
      _lessonOpen = false;
    }
  }

  void _claimQuest(LearningProgress progress, String id, int goal, int reward) {
    final day = localDay(DateTime.now());
    final next = progress.claimDaily(id, day, goal, reward);
    if (identical(next, progress)) return;
    _update(next, message: 'Hadiah misi diterima. +$reward Gems!');
  }

  void _claimMilestone(LearningProgress progress, int target, int reward) {
    final next = progress.claimMilestone(target, reward);
    if (identical(next, progress)) return;
    _update(next, message: 'Peti pencapaian dibuka. +$reward Gems!');
  }

  Future<void> _rename(LearningProgress progress, String name) async {
    final updated = await showDialog<String>(
      context: context,
      builder: (context) => _NameDialog(name: name),
    );
    if (mounted && updated != null) {
      _update(progress.copyWith(displayName: updated));
    }
  }

  Future<void> _editProfile(LearningProgress progress, String name) async {
    final choice = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit profil',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text('Pilih art profil yang sudah dibuka di Toko.'),
              const SizedBox(height: 18),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (var id = 0; id < avatarNames.length; id++)
                    InkWell(
                      onTap: progress.ownedAvatars.contains(id)
                          ? () => Navigator.of(sheetContext).pop(id)
                          : null,
                      child: Opacity(
                        opacity: progress.ownedAvatars.contains(id) ? 1 : .45,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ProfileArt(id: id, size: 62),
                            Text(
                              avatarNames[id],
                              style: const TextStyle(fontSize: 11),
                            ),
                            if (!progress.ownedAvatars.contains(id))
                              const Icon(Icons.lock_rounded, size: 14),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(sheetContext).pop(-2),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Ubah nama'),
              ),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(-3),
                child: const Text('Lihat art profil di Toko'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice >= 0) _update(progress.equipAvatar(choice));
    if (choice == -2) _rename(progress, name);
    if (choice == -3) setState(() => _tab = _Destination.shop);
  }

  void _showRankList() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          RankListSheet(current: rankForXp((_progress?.xp) ?? 0)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LearningProgress>(
      future: _loading,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('LingoShark')),
            body: Center(
              child: snapshot.hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Progres gagal dimuat.'),
                        TextButton(
                          onPressed: () =>
                              setState(() => _loading = _store.load()),
                          child: const Text('Coba lagi'),
                        ),
                        TextButton(
                          onPressed: widget.onSignOut,
                          child: const Text('Keluar'),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(
                      semanticsLabel: 'Memuat progres',
                    ),
            ),
          );
        }
        final progress = _progress ?? snapshot.requireData;
        final day = localDay(DateTime.now());
        final goal = progress.dailyGoal ?? widget.profile.dailyGoal;
        final name = progress.displayName ?? widget.profile.name;

        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 744;
            final content = switch (_tab) {
              _Destination.learn => <Widget>[],
              _Destination.quests => _quests(progress, goal, day),
              _Destination.ranks => _ranks(progress, name),
              _Destination.shop => _shop(progress),
              _Destination.profile => _profile(progress, name, day),
            };
            return SharkSkinScope(
              skinId: progress.skinId,
              child: Scaffold(
                extendBody: true,
                backgroundColor: _tab == _Destination.learn
                    ? const Color(0xFFB8EAF4)
                    : const Color(0xFFF3F8FC),
                appBar: PreferredSize(
                  preferredSize: const Size.fromHeight(78),
                  child: SafeArea(
                    bottom: false,
                    child: _DynamicHeader(
                      streak: progress.activeStreak(day),
                      gems: progress.gems,
                    ),
                  ),
                ),
                bottomNavigationBar: LearningTabBar(
                  selectedIndex: _tab.index,
                  onSelected: (index) {
                    final next = _Destination.values[index];
                    if (next == _tab) return;
                    setState(() {
                      _tab = next;
                      _recentlyCompleted = null;
                    });
                  },
                  destinations: [
                    for (final page in _Destination.values)
                      NavigationDestination(
                        icon: Icon(page.icon),
                        label: page.label,
                      ),
                  ],
                ),
                body: SafeArea(
                  bottom: false,
                  child: _tab == _Destination.learn
                      ? LearningPath(
                          lessons: lessons,
                          completed: progress.completed,
                          animate: progress.motion,
                          recentlyCompleted: _recentlyCompleted,
                          onOpen: (lesson) => _openLesson(lesson, progress),
                        )
                      : Builder(
                          builder: (context) => Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 704),
                              child: ListView(
                                key: ValueKey(_tab),
                                padding: EdgeInsets.fromLTRB(
                                  wide ? 32 : 16,
                                  wide ? 28 : 12,
                                  wide ? 32 : 16,
                                  MediaQuery.paddingOf(context).bottom + 110,
                                ),
                                children: content,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _quests(LearningProgress progress, int goal, int day) => [
    const _Heading(title: 'Quest', detail: 'Jelajahi laut, kumpulkan harta.'),
    const SizedBox(height: 18),
    _QuestHero(lessonsToday: progress.lessonsOn(day)),
    const SizedBox(height: 22),
    const _SectionLabel(icon: Icons.explore_rounded, title: 'Misi hari ini'),
    const SizedBox(height: 12),
    _QuestCard(
      title: 'Berlayar pertama',
      detail: 'Selesaikan 1 latihan hari ini',
      icon: Icons.sailing_rounded,
      count: progress.lessonsOn(day),
      target: 1,
      reward: 5,
      claimed: progress.dailyClaimed('first', day),
      onClaim: _saving ? null : () => _claimQuest(progress, 'first', 1, 5),
    ),
    const SizedBox(height: 12),
    _QuestCard(
      title: 'Tujuan kapten',
      detail: 'Penuhi target belajar harianmu',
      icon: Icons.navigation_rounded,
      count: progress.lessonsOn(day),
      target: goal,
      reward: 15,
      claimed: progress.dailyClaimed('goal', day),
      mainQuest: true,
      onClaim: _saving ? null : () => _claimQuest(progress, 'goal', goal, 15),
    ),
    const SizedBox(height: 12),
    _QuestCard(
      title: 'Arungi tiga ombak',
      detail: 'Selesaikan 3 latihan hari ini',
      icon: Icons.waves_rounded,
      count: progress.lessonsOn(day),
      target: 3,
      reward: 10,
      claimed: progress.dailyClaimed('three', day),
      onClaim: _saving ? null : () => _claimQuest(progress, 'three', 3, 10),
    ),
    const SizedBox(height: 24),
    const _SectionLabel(
      icon: Icons.emoji_events_rounded,
      title: 'Peti pencapaian',
    ),
    const SizedBox(height: 12),
    for (final target in [5, 20, 50, 100]) ...[
      _QuestCard(
        title: 'Penjelajah $target pulau',
        detail: 'Tuntaskan $target level di peta',
        icon: Icons.workspace_premium_rounded,
        count: progress.completed.length,
        target: target,
        reward: target == 100
            ? 100
            : target == 50
            ? 50
            : target == 20
            ? 25
            : 10,
        claimed: progress.milestoneClaims.contains(target),
        onClaim: _saving
            ? null
            : () => _claimMilestone(
                progress,
                target,
                target == 100
                    ? 100
                    : target == 50
                    ? 50
                    : target == 20
                    ? 25
                    : 10,
              ),
      ),
      const SizedBox(height: 12),
    ],
  ];

  List<Widget> _ranks(LearningProgress progress, String name) {
    final roster =
        [
          (name: 'Nara', xp: 1120, me: false),
          (name: 'Ari', xp: 470, me: false),
          (name: 'Mira', xp: 330, me: false),
          (name: 'Dimas', xp: 245, me: false),
          (name: 'Sari', xp: 145, me: false),
          (name: 'Raka', xp: 75, me: false),
          (name: 'Lia', xp: 40, me: false),
          (name: 'Bimo', xp: 20, me: false),
          (name: name, xp: progress.xp, me: true),
        ]..sort(
          (a, b) =>
              a.xp == b.xp ? a.name.compareTo(b.name) : b.xp.compareTo(a.xp),
        );
    return [
      const _Heading(
        title: 'Peringkat',
        detail: 'Liga demo · berdasarkan XP lokal.',
      ),
      const SizedBox(height: 18),
      _Panel(
        children: [
          const _Title(icon: Icons.emoji_events_rounded, title: 'Liga Karang'),
          const SizedBox(height: 12),
          for (final (index, member) in roster.indexed)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              tileColor: member.me ? _ice : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Row(
                children: [
                  RankBadge(rank: rankForXp(member.xp), size: 28),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      member.me ? '${member.name} (kamu)' : member.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 37),
                child: Text(rankForXp(member.xp).label),
              ),
              trailing: Text('${member.xp} XP'),
            ),
        ],
      ),
    ];
  }

  List<Widget> _shop(LearningProgress progress) => [
    _Heading(title: 'Toko', detail: 'Saldo kamu: ${progress.gems} gems.'),
    const SizedBox(height: 18),
    _Panel(
      children: [
        const _Title(icon: Icons.ac_unit_rounded, title: 'Pelindung streak'),
        const SizedBox(height: 12),
        const Text(
          'Menjaga streak saat kamu melewatkan satu hari. Terpakai jika kamu kembali berlatih keesokan harinya.',
        ),
        const SizedBox(height: 8),
        MotionReveal(
          key: ValueKey(progress.freezes),
          child: Text('Dimiliki: ${progress.freezes}'),
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: _saving || progress.gems < 25
              ? null
              : () => _update(
                  progress.copyWith(
                    gems: progress.gems - 25,
                    freezes: progress.freezes + 1,
                  ),
                  message: 'Pelindung streak dibeli.',
                ),
          child: const Text('Beli · 25 gems'),
        ),
      ],
    ),
    const SizedBox(height: 14),
    _Panel(
      children: [
        const _Title(icon: Icons.bolt_rounded, title: 'XP Boosters'),
        const SizedBox(height: 8),
        const Text(
          'Setiap booster aktif selama 5 menit. Selama itu semua XP yang kamu dapat bertambah sesuai persentasenya.',
        ),
        const SizedBox(height: 12),
        BoostCountdown(
          dark: false,
          percent: progress.activeBoost,
          untilMs: progress.boostUntil,
          onExpired: () {
            if (mounted) setState(() {});
          },
        ),
        for (final percent in [5, 7, 10])
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  '+$percent% XP',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  'Stok ${progress.boosters[percent] ?? 0}${progress.boostPercentAt(DateTime.now().millisecondsSinceEpoch) == percent ? ' · aktif' : ''}',
                ),
                if ((progress.boosters[percent] ?? 0) > 0)
                  TextButton(
                    onPressed:
                        _saving ||
                            progress.boostRemainingMs(
                                  DateTime.now().millisecondsSinceEpoch,
                                ) >
                                0
                        ? null
                        : () => _update(
                            progress.activateBoost(percent),
                            message: 'Booster $percent% aktif selama 5 menit.',
                          ),
                    child: const Text('Aktifkan'),
                  ),
                FilledButton.tonal(
                  onPressed:
                      _saving ||
                          progress.gems < LearningProgress.boostPrice(percent)
                      ? null
                      : () => _update(
                          progress.buyBoost(percent),
                          message: 'Booster $percent% dibeli.',
                        ),
                  child: Text(
                    'Beli ${LearningProgress.boostPrice(percent)} Gems',
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
    const SizedBox(height: 14),
    _Panel(
      children: [
        const _Title(icon: Icons.palette_rounded, title: 'Art profil'),
        const SizedBox(height: 8),
        const Text('Lima art eksklusif · 15 Gems per art.'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var id = 0; id < avatarNames.length; id++)
              _StoreChoice(
                name: avatarNames[id],
                price: 15,
                owned: progress.ownedAvatars.contains(id),
                active: progress.avatarId == id,
                canBuy: progress.gems >= 15,
                preview: ProfileArt(id: id, size: 58),
                onPressed: _saving
                    ? null
                    : () => _update(
                        progress.ownedAvatars.contains(id)
                            ? progress.equipAvatar(id)
                            : progress.buyAvatar(id),
                        message: progress.ownedAvatars.contains(id)
                            ? '${avatarNames[id]} dipakai.'
                            : '${avatarNames[id]} dibeli.',
                      ),
              ),
          ],
        ),
      ],
    ),
    const SizedBox(height: 14),
    _Panel(
      children: [
        const _Title(
          icon: Icons.face_retouching_natural_rounded,
          title: 'Skin hiu',
        ),
        const SizedBox(height: 8),
        const Text(
          'Lima kostum maskot · 25 Gems per skin. Skin terpasang muncul di peta dan quiz.',
        ),
        const SizedBox(height: 14),
        Column(
          children: [
            for (var id = 0; id < sharkSkinNames.length; id++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SkinChoice(
                  name: sharkSkinNames[id],
                  owned: progress.ownedSkins.contains(id),
                  active: progress.skinId == id,
                  canBuy: progress.gems >= 25,
                  skinId: id,
                  onPressed: _saving
                      ? null
                      : () => _update(
                          progress.ownedSkins.contains(id)
                              ? progress.equipSkin(id)
                              : progress.buySkin(id),
                          message: progress.ownedSkins.contains(id)
                              ? '${sharkSkinNames[id]} dipakai.'
                              : '${sharkSkinNames[id]} dibeli.',
                        ),
                ),
              ),
          ],
        ),
      ],
    ),
  ];

  List<Widget> _profile(LearningProgress progress, String name, int day) => [
    const _Heading(title: 'Profil', detail: 'Akun petualanganmu'),
    const SizedBox(height: 18),
    _ProfileHero(
      avatarId: progress.avatarId,
      name: name,
      email: widget.profile.email,
      streak: progress.activeStreak(day),
      completed: progress.completed.length,
      onEdit: _saving ? null : () => _editProfile(progress, name),
    ),
    const SizedBox(height: 14),
    RankShowcase(
      xp: progress.xp,
      onInfo: _showRankList,
      boostPercent: progress.activeBoost,
      boostUntilMs: progress.boostUntil,
    ),
    const SizedBox(height: 20),
    OutlinedButton(
      onPressed: _saving ? null : widget.onSignOut,
      child: const Text('Keluar'),
    ),
  ];
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.avatarId,
    required this.name,
    required this.email,
    required this.streak,
    required this.completed,
    required this.onEdit,
  });
  final int avatarId;
  final String name;
  final String email;
  final int streak;
  final int completed;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(21),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF06365C), Color(0xFF087AA5), Color(0xFF55C4D5)],
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [
        BoxShadow(
          color: Color(0x30053D6E),
          blurRadius: 18,
          offset: Offset(0, 9),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Profil pelajar',
          style: TextStyle(
            color: Color(0xFFB0F1FF),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.7,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: ProfileArt(id: avatarId, size: 78),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFE2F6FF)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 9,
          children: [
            _ProfileStat(
              icon: Icons.local_fire_department_rounded,
              value: '$streak',
              label: 'hari streak',
            ),
            _ProfileStat(
              icon: Icons.check_circle_rounded,
              value: '$completed',
              label: 'lesson selesai',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: onEdit,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _navy,
            ),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Edit Profil'),
          ),
        ),
      ],
    ),
  );
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0x33001B33),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0x6684E3EF)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFFFCF86), size: 19),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '$value $label',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SkinChoice extends StatelessWidget {
  const _SkinChoice({
    required this.name,
    required this.owned,
    required this.active,
    required this.canBuy,
    required this.skinId,
    required this.onPressed,
  });
  final String name;
  final bool owned;
  final bool active;
  final bool canBuy;
  final int skinId;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: active ? const Color(0xFFE4F5FF) : const Color(0xFFF5FAFD),
      borderRadius: BorderRadius.circular(19),
      border: Border.all(
        color: active ? _blue : _outline,
        width: active ? 2 : 1,
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: const Color(0xFFCDECF8),
            borderRadius: BorderRadius.circular(15),
          ),
          child: SharkSkinScope(
            skinId: skinId,
            child: SharkMascot(size: 73, animate: false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                active
                    ? 'Sedang dipakai'
                    : owned
                    ? 'Sudah dimiliki'
                    : '25 Gems · terkunci',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        SizedBox(
          width: 76,
          child: FilledButton.tonal(
            onPressed: active || (!owned && !canBuy) ? null : onPressed,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            child: Text(
              active
                  ? 'Dipakai'
                  : owned
                  ? 'Pakai'
                  : 'Beli',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    ),
  );
}

class _StoreChoice extends StatelessWidget {
  const _StoreChoice({
    required this.name,
    required this.price,
    required this.owned,
    required this.active,
    required this.canBuy,
    required this.preview,
    required this.onPressed,
  });

  final String name;
  final int price;
  final bool owned;
  final bool active;
  final bool canBuy;
  final Widget preview;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Container(
    width: 116,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: active ? const Color(0xFFE4F5FF) : const Color(0xFFF5FAFD),
      border: Border.all(
        color: active ? _blue : _outline,
        width: active ? 2 : 1,
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        SizedBox(height: 70, child: Center(child: preview)),
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        ),
        Text(
          owned ? 'Terbuka' : 'Terkunci',
          style: const TextStyle(fontSize: 11, color: _muted),
        ),
        const SizedBox(height: 7),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            onPressed: active || (!owned && !canBuy) ? null : onPressed,
            child: Text(
              active
                  ? 'Dipakai'
                  : owned
                  ? 'Pakai'
                  : 'Beli $price',
            ),
          ),
        ),
      ],
    ),
  );
}

class _DynamicHeader extends StatelessWidget {
  const _DynamicHeader({required this.streak, required this.gems});

  final int streak;
  final int gems;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: Container(
          height: 61,
          decoration: BoxDecoration(
            color: const Color(0xF20A2D4B),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: const Color(0xFF70C7E6), width: 1.4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3305446E),
                blurRadius: 18,
                offset: Offset(0, 7),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              SizedBox(
                width: 57,
                child: _IslandMetric(
                  icon: Icons.local_fire_department_rounded,
                  value: streak,
                  color: const Color(0xFFFFA656),
                  label: 'hari streak',
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFB7EAFF),
                        shape: BoxShape.circle,
                      ),
                      child: const ClipOval(
                        child: SharkMascot(size: 36, animate: false),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Flexible(
                      child: Text(
                        'LingoShark',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 57,
                child: _IslandMetric(
                  icon: Icons.diamond_rounded,
                  value: gems,
                  color: const Color(0xFF71D5FF),
                  label: 'gems',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _IslandMetric extends StatelessWidget {
  const _IslandMetric({
    required this.icon,
    required this.value,
    required this.color,
    required this.label,
  });
  final IconData icon;
  final int value;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$value $label',
    excludeSemantics: true,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 19),
        const SizedBox(width: 2),
        Flexible(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              '$value',
              key: ValueKey(value),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _QuestHero extends StatelessWidget {
  const _QuestHero({required this.lessonsToday});
  final int lessonsToday;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(21),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF073D69), Color(0xFF078AB6)],
      ),
      borderRadius: BorderRadius.circular(26),
      boxShadow: const [
        BoxShadow(
          color: Color(0x26045587),
          blurRadius: 17,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PAPAN MISI',
                style: TextStyle(
                  color: Color(0xFF86E6FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cari harta di setiap ombak',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                '$lessonsToday latihan hari ini · misi baru setiap hari',
                style: const TextStyle(color: Color(0xFFD8F5FF)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.inventory_2_rounded,
          size: 67,
          color: Color(0xFFFFC875),
        ),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: _blue),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: _navy,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ],
  );
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({
    required this.title,
    required this.detail,
    required this.icon,
    required this.count,
    required this.target,
    required this.reward,
    required this.claimed,
    required this.onClaim,
    this.mainQuest = false,
  });
  final String title;
  final String detail;
  final IconData icon;
  final int count;
  final int target;
  final int reward;
  final bool claimed;
  final bool mainQuest;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final ready = count >= target;
    return Container(
      decoration: BoxDecoration(
        color: claimed ? const Color(0xFFE5F4EF) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: ready ? const Color(0xFF58B5C9) : _outline,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F5FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _blue),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      detail,
                      style: const TextStyle(color: _muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.inventory_2_rounded,
                color: Color(0xFFBC782B),
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 13),
          MotionProgress(
            value: (count / target).clamp(0.0, 1.0),
            label: 'Progres $title',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${count.clamp(0, target)} / $target · +$reward Gems',
                  style: const TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(
                width: 126,
                height: 36,
                child: FilledButton(
                  onPressed: ready && !claimed ? onClaim : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                  ),
                  child: Text(
                    claimed
                        ? 'Sudah diklaim'
                        : mainQuest
                        ? 'Klaim hadiah'
                        : 'Ambil hadiah',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: const TextStyle(
              color: _navy,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -1.05,
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(detail, style: const TextStyle(color: _muted, fontSize: 15)),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: _outline),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: _blue),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
        ),
      ),
    ],
  );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.name});

  final String name;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.name);
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_form.currentState!.validate()) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Ubah nama'),
    content: Form(
      key: _form,
      child: TextFormField(
        controller: _controller,
        autofocus: true,
        inputFormatters: [LengthLimitingTextInputFormatter(60)],
        decoration: const InputDecoration(labelText: 'Nama panggilan'),
        validator: (value) =>
            value!.trim().isEmpty ? 'Masukkan nama panggilan.' : null,
        onFieldSubmitted: (_) => _submit(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Batal'),
      ),
      TextButton(onPressed: _submit, child: const Text('Simpan')),
    ],
  );
}
