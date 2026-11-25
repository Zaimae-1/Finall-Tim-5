import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/motion.dart';
import '../../shared/shark_mascot.dart';
import '../auth/local_profiles.dart';
import 'course.dart';
import 'learning_progress.dart';
import 'learning_tab_bar.dart';
import 'lesson_page.dart';

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
          builder: (context) => LessonPage(
            lesson: lesson,
            animateMascot: progress.motion,
            onComplete: (perfect) async {
              final current = _progress ?? progress;
              final xp = current.rewardXp(lesson.id, perfect);
              await _save(
                current.finish(lesson.id, perfect, localDay(DateTime.now())),
              );
              return xp;
            },
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
            final showAside =
                constraints.maxWidth >= 1120 && _tab == _Destination.learn;
            final content = switch (_tab) {
              _Destination.learn => _learn(progress, goal, day, showAside),
              _Destination.quests => _quests(progress, goal, day),
              _Destination.ranks => _ranks(progress, name),
              _Destination.shop => _shop(progress),
              _Destination.profile => _profile(progress, name, goal, day),
            };
            return Scaffold(
              extendBody: true,
              backgroundColor: const Color(0xFFF3F8FC),
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
                child: Builder(
                  builder: (context) => Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: showAside ? 1040 : 704,
                      ),
                      child: ListView(
                        key: ValueKey(_tab),
                        padding: EdgeInsets.fromLTRB(
                          wide ? 32 : 16,
                          wide ? 28 : 12,
                          wide ? 32 : 16,
                          MediaQuery.paddingOf(context).bottom + 16,
                        ),
                        children: showAside
                            ? [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: content,
                                      ),
                                    ),
                                    const SizedBox(width: 22),
                                    SizedBox(
                                      width: 250,
                                      child: _questCard(progress, goal, day),
                                    ),
                                  ],
                                ),
                              ]
                            : content,
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

  List<Widget> _learn(
    LearningProgress progress,
    int goal,
    int day,
    bool showAside,
  ) {
    final finished = progress.completed.length;
    return [
      const _Heading(title: 'Jalur belajar', detail: 'Bahasa Inggris · Unit 1'),
      const SizedBox(height: 18),
      _CourseBanner(finished: finished, animateMascot: progress.motion),
      const SizedBox(height: 25),
      for (var i = 0; i < lessons.length; i++)
        _lessonStop(
          lessons[i],
          i,
          progress,
          unlocked: i == 0 || progress.completed.contains(lessons[i - 1].id),
        ),
      if (!showAside) ...[
        const SizedBox(height: 24),
        _questCard(progress, goal, day),
      ],
    ];
  }

  Widget _lessonStop(
    Lesson lesson,
    int index,
    LearningProgress progress, {
    required bool unlocked,
  }) {
    final done = progress.completed.contains(lesson.id);
    final icon = done
        ? Icons.check_rounded
        : unlocked
        ? Icons.play_arrow_rounded
        : Icons.lock_outline_rounded;
    final marker = Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: !unlocked
            ? const Color(0xFFE5EEF5)
            : (done ? const Color(0xFFDFF4EE) : _blue),
        shape: BoxShape.circle,
        boxShadow: unlocked && !done
            ? const [BoxShadow(color: Color(0xFF06457B), offset: Offset(0, 4))]
            : null,
      ),
      child: Icon(
        icon,
        color: !unlocked
            ? _muted
            : (done ? const Color(0xFF177054) : Colors.white),
      ),
    );
    final justUnlocked =
        index > 0 && !done && lessons[index - 1].id == _recentlyCompleted;
    return Padding(
      padding: EdgeInsets.only(left: index.isOdd ? 22 : 0, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (justUnlocked)
            MotionReveal(
              key: ValueKey(lesson.id),
              duration: const Duration(milliseconds: 340),
              startScale: .68,
              lift: 10,
              child: marker,
            )
          else
            marker,
          const SizedBox(width: 13),
          Expanded(
            child: Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: _outline),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                title: Text(
                  lesson.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  unlocked
                      ? lesson.description
                      : 'Terkunci · selesaikan lesson sebelumnya',
                ),
                trailing: unlocked
                    ? const Icon(Icons.chevron_right_rounded)
                    : null,
                onTap: unlocked ? () => _openLesson(lesson, progress) : null,
              ),
            ),
          ),
        ],
      ),
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
          (name: 'Nara', xp: 40, me: false),
          (name: 'Ari', xp: 25, me: false),
          (name: 'Mira', xp: 12, me: false),
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
              title: Text(member.me ? '${member.name} (kamu)' : member.name),
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
  ];

  List<Widget> _profile(
    LearningProgress progress,
    String name,
    int goal,
    int day,
  ) => [
    _Heading(title: name, detail: widget.profile.email),
    const SizedBox(height: 18),
    _Panel(
      children: [
        const _Title(icon: Icons.person_rounded, title: 'Profil pelajar'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 18,
          runSpacing: 10,
          children: [
            _Metric(
              icon: Icons.bolt_rounded,
              value: '${progress.xp}',
              label: 'XP',
              color: _blue,
            ),
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
          onPressed: _saving ? null : () => _rename(progress, name),
          child: const Text('Ubah nama'),
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

class _CourseBanner extends StatelessWidget {
  const _CourseBanner({required this.finished, required this.animateMascot});

  final int finished;
  final bool animateMascot;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        gradient: const LinearGradient(
          colors: [Color(0xFF0D3757), Color(0xFF116898)],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final art = (constraints.maxWidth * .36).clamp(88.0, 176.0);
          const artInset = 12.0;
          return ConstrainedBox(
            constraints: BoxConstraints(minHeight: art + artInset * 2),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Positioned(
                  right: -art * .07,
                  bottom: -art * .18,
                  child: Container(
                    width: art * 1.28,
                    height: art * 1.28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0x224DC5F5),
                      border: Border.all(
                        color: const Color(0x55A9E8FF),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: artInset,
                  top: artInset,
                  bottom: artInset,
                  child: Center(
                    child: SharkMascot(size: art, animate: animateMascot),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 22, art + artInset * 2, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Percakapan pertama',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                          height: 1.05,
                          letterSpacing: -.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Sapa, kenalan, lalu pesan makanan.',
                        style: TextStyle(color: Color(0xFFDAF2FF), height: 1.4),
                      ),
                      const SizedBox(height: 13),
                      Text(
                        '$finished / ${lessons.length} lesson selesai',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
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
