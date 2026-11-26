import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/motion.dart';
import '../../shared/shark_mascot.dart';
import '../auth/local_profiles.dart';
import 'course.dart';
import 'learning_progress.dart';
import 'learning_path.dart';
import 'learning_tab_bar.dart';
import 'lesson_page.dart';
import 'profile_art.dart';
import 'rank.dart';

const _navy = Color(0xFF103552);
const _blue = Color(0xFF075DAB);
const _muted = Color(0xFF47647A);
const _outline = Color(0xFFD8E6F0);
const _ice = Color(0xFFE5F3FF);
const _coral = Color(0xFFA84E18);

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
    } finally {
      _lessonOpen = false;
    }
  }

  void _claimQuest(LearningProgress progress, int goal) {
    final day = localDay(DateTime.now());
    if (progress.claimDay == day || progress.lessonsOn(day) < goal) return;
    _update(
      progress.copyWith(claimDay: day, gems: progress.gems + 15),
      message: 'Hadiah quest diterima. +15 gems!',
    );
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
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .76,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'Daftar semua rank',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final tier in RankTier.values)
                      ListTile(
                        leading: RankBadge(rank: tier, size: 42),
                        title: Text(
                          tier.label,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          tier.next == null
                              ? '${tier.minXp}+ XP'
                              : '${tier.minXp}–${tier.next!.minXp - 1} XP',
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
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
              _Destination.profile => _profile(progress, name, goal, day),
            };
            return SharkSkinScope(
              skinId: progress.skinId,
              child: Scaffold(
                extendBody: true,
                backgroundColor: _tab == _Destination.learn
                    ? const Color(0xFFB8EAF4)
                    : const Color(0xFFF3F8FC),
                appBar: AppBar(
                  title: const _Brand(),
                  actions: [
                    _Metric(
                      icon: Icons.local_fire_department_rounded,
                      value: '${progress.activeStreak(day)}',
                      label: 'hari streak',
                      color: _coral,
                    ),
                    const SizedBox(width: 12),
                    _Metric(
                      icon: Icons.diamond_rounded,
                      value: '${progress.gems}',
                      label: 'gems',
                      color: _blue,
                    ),
                    const SizedBox(width: 16),
                  ],
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
                                  MediaQuery.paddingOf(context).bottom + 16,
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

  Widget _questCard(LearningProgress progress, int goal, int day) {
    final count = progress.lessonsOn(day).clamp(0, goal);
    final claimed = progress.claimDay == day;
    return _Panel(
      children: [
        const _Title(icon: Icons.flag_rounded, title: 'Quest harian'),
        const SizedBox(height: 14),
        Text('Selesaikan $goal lesson hari ini.'),
        const SizedBox(height: 10),
        MotionProgress(value: count / goal, label: 'Progres quest'),
        const SizedBox(height: 8),
        Text('$count / $goal lesson · +15 gems'),
        const SizedBox(height: 14),
        MotionReveal(
          key: ValueKey(claimed),
          startScale: .92,
          lift: 4,
          child: FilledButton(
            onPressed: !claimed && count == goal && !_saving
                ? () => _claimQuest(progress, goal)
                : null,
            child: Text(claimed ? 'Sudah diklaim' : 'Klaim hadiah'),
          ),
        ),
      ],
    );
  }

  List<Widget> _quests(LearningProgress progress, int goal, int day) => [
    const _Heading(title: 'Quest', detail: 'Hadiah untuk latihan hari ini.'),
    const SizedBox(height: 18),
    _questCard(progress, goal, day),
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
          'Pakai satu booster pada penyelesaian level baru berikutnya.',
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
                  'Stok ${progress.boosters[percent] ?? 0}${progress.activeBoost == percent ? ' · aktif' : ''}',
                ),
                if ((progress.boosters[percent] ?? 0) > 0 &&
                    progress.activeBoost != percent)
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => _update(progress.equipBoost(percent)),
                    child: const Text('Pakai'),
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
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var id = 0; id < sharkSkinNames.length; id++)
              _StoreChoice(
                name: sharkSkinNames[id],
                price: 25,
                owned: progress.ownedSkins.contains(id),
                active: progress.skinId == id,
                canBuy: progress.gems >= 25,
                preview: SharkSkinScope(
                  skinId: id,
                  child: SharkMascot(size: 67, animate: false),
                ),
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
          ],
        ),
      ],
    ),
  ];

  List<Widget> _profile(
    LearningProgress progress,
    String name,
    int goal,
    int day,
  ) => [
    const _Heading(title: 'Profil', detail: 'Akun petualanganmu'),
    const SizedBox(height: 18),
    _Panel(
      children: [
        const _Title(icon: Icons.person_rounded, title: 'Profil pelajar'),
        const SizedBox(height: 12),
        Row(
          children: [
            ProfileArt(id: progress.avatarId, size: 78),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: _navy,
                    ),
                  ),
                  Text(
                    widget.profile.email,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Statistik', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 18,
          runSpacing: 10,
          children: [
            _Metric(
              icon: Icons.local_fire_department_rounded,
              value: '${progress.activeStreak(day)}',
              label: 'hari streak',
              color: _coral,
            ),
            _Metric(
              icon: Icons.check_circle_rounded,
              value: '${progress.completed.length}',
              label: 'lesson',
              color: const Color(0xFF177054),
            ),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _saving ? null : () => _editProfile(progress, name),
          child: const Text('Edit Profil'),
        ),
      ],
    ),
    const SizedBox(height: 14),
    _Panel(
      children: [
        Row(
          children: [
            const Expanded(
              child: _Title(
                icon: Icons.military_tech_rounded,
                title: 'Rank kamu',
              ),
            ),
            IconButton(
              tooltip: 'Lihat semua rank',
              onPressed: _showRankList,
              icon: const Icon(Icons.info_outline_rounded, color: _blue),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            RankBadge(rank: rankForXp(progress.xp), size: 74),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rankForXp(progress.xp).label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      color: _navy,
                    ),
                  ),
                  Text(
                    '${progress.xp} XP terkumpul',
                    style: const TextStyle(color: _muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        MotionProgress(value: rankProgress(progress.xp), label: 'Progres rank'),
        const SizedBox(height: 8),
        Text(
          rankForXp(progress.xp).next == null
              ? 'Rank tertinggi tercapai!'
              : '${rankForXp(progress.xp).next!.minXp - progress.xp} XP lagi menuju ${rankForXp(progress.xp).next!.label}',
        ),
      ],
    ),
    const SizedBox(height: 14),
    _Panel(
      children: [
        const _Title(icon: Icons.tune_rounded, title: 'Pengaturan belajar'),
        const SizedBox(height: 14),
        Text('Level awal: ${widget.profile.level}'),
        const SizedBox(height: 14),
        DropdownButtonFormField<int>(
          initialValue: goal,
          decoration: const InputDecoration(labelText: 'Target harian'),
          items: [
            for (final count in [1, 2, 3])
              DropdownMenuItem(value: count, child: Text('$count lesson')),
          ],
          onChanged: _saving
              ? null
              : (count) {
                  if (count != null && count != goal) {
                    _update(progress.copyWith(dailyGoal: count));
                  }
                },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Gerakan maskot'),
          value: progress.motion,
          onChanged: _saving
              ? null
              : (value) => _update(progress.copyWith(motion: value)),
        ),
      ],
    ),
    const SizedBox(height: 20),
    OutlinedButton(
      onPressed: _saving ? null : widget.onSignOut,
      child: const Text('Keluar'),
    ),
  ];
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

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.waves_rounded, color: _blue, size: 25),
        SizedBox(width: 7),
        Flexible(
          child: Text(
            'LingoShark',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _navy,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: -.8,
            ),
          ),
        ),
      ],
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

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 4),
          MotionReveal(
            key: ValueKey(value),
            startScale: 1.18,
            lift: 3,
            child: Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
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
