import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../shared/shark_mascot.dart';
import 'course.dart';

class LessonPage extends StatefulWidget {
  const LessonPage({
    super.key,
    required this.lesson,
    required this.onComplete,
    required this.animateMascot,
  });

  final Lesson lesson;
  final Future<int> Function(bool perfect) onComplete;
  final bool animateMascot;

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  int _index = 0;
  int _correctCount = 0;
  int _hearts = 5;
  int? _choice;
  int? _matchingWord;
  final _ordered = <int>[];
  final _pairs = <int, int>{};
  bool? _correct;
  int? _earnedXp;
  bool _saving = false;
  bool _saveFailed = false;
  bool _confirmingExit = false;

  Exercise get _exercise => widget.lesson.exercises[_index];

  bool get _ready => switch (_exercise.kind) {
    ExerciseKind.choice => _choice != null,
    ExerciseKind.order => _ordered.isNotEmpty,
    ExerciseKind.match => _pairs.length == _exercise.words.length,
  };

  void _check() {
    if (_correct != null || !_ready) return;
    final correct = switch (_exercise.kind) {
      ExerciseKind.choice => _choice == _exercise.correctChoice,
      ExerciseKind.order => listEquals(_ordered, _exercise.answer),
      ExerciseKind.match => listEquals(
        List.generate(_exercise.words.length, (index) => _pairs[index]),
        _exercise.answer,
      ),
    };
    setState(() {
      _correct = correct;
      if (correct) {
        _correctCount++;
      } else {
        _hearts--;
      }
    });
  }

  void _clearAnswer() {
    _choice = null;
    _matchingWord = null;
    _correct = null;
    _ordered.clear();
    _pairs.clear();
  }

  Future<void> _advance() async {
    if (_saving || _correct == null) return;
    if (_index < widget.lesson.exercises.length - 1) {
      setState(() {
        _index++;
        _clearAnswer();
      });
      return;
    }

    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      final xp = await widget.onComplete(
        _correctCount == widget.lesson.exercises.length,
      );
      if (mounted) setState(() => _earnedXp = xp);
    } on Exception {
      if (mounted) setState(() => _saveFailed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _exit() async {
    if (_saving || _confirmingExit) return;
    if (_earnedXp != null || _hearts == 0) {
      Navigator.of(context).pop();
      return;
    }
    _confirmingExit = true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tinggalkan latihan?'),
        content: const Text('Jawaban pada latihan ini akan direset.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tetap belajar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    _confirmingExit = false;
    if (mounted && leave == true) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.lesson.exercises.length;
    final showSummary = _earnedXp != null || _hearts == 0;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Tutup latihan',
            onPressed: _saving ? null : _exit,
            icon: const Icon(Icons.close_rounded),
          ),
          title: Text(widget.lesson.title),
          actions: [
            if (!showSummary)
              Padding(
                padding: const EdgeInsets.only(right: 18),
                child: Row(
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFBA3454),
                    ),
                    const SizedBox(width: 6),
                    Text('$_hearts', style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 570),
              child: ListView(
                key: ValueKey((_index, showSummary)),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: showSummary
                    ? _summary(context, total)
                    : [
                        LinearProgressIndicator(
                          value: (_index + (_correct == null ? 0 : 1)) / total,
                          minHeight: 9,
                          borderRadius: BorderRadius.circular(10),
                          semanticsLabel: 'Progres latihan',
                        ),
                        const SizedBox(height: 16),
                        Text('Soal ${_index + 1} dari $total'),
                        const SizedBox(height: 14),
                        Semantics(
                          header: true,
                          child: Text(
                            _exercise.prompt,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ..._answers(),
                        const SizedBox(height: 24),
                        if (_correct case final answerCorrect?)
                          _Feedback(
                            correct: answerCorrect,
                            solution: _exercise.solution,
                          ),
                        if (_saveFailed)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              'Progres gagal disimpan. Coba lagi.',
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _saving
                              ? null
                              : (_correct != null
                                    ? _advance
                                    : (_ready ? _check : null)),
                          child: Text(
                            _saving
                                ? 'Menyimpan…'
                                : _saveFailed
                                ? 'Coba simpan lagi'
                                : _correct != null
                                ? 'Lanjut'
                                : 'Periksa jawaban',
                          ),
                        ),
                      ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _answers() {
    final exercise = _exercise;
    final enabled = _correct == null;
    switch (exercise.kind) {
      case ExerciseKind.choice:
        return List.generate(exercise.options.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _AnswerTile(
              label: exercise.options[index],
              selected: _choice == index,
              onTap: enabled ? () => setState(() => _choice = index) : null,
            ),
          );
        });
      case ExerciseKind.order:
        return [
          Container(
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(minHeight: 72),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFA3BCCC)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _ordered.isEmpty
                ? const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Susun kata di sini'),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final index in _ordered)
                        _AnswerTile(
                          label: exercise.options[index],
                          selected: true,
                          onTap: enabled
                              ? () => setState(() => _ordered.remove(index))
                              : null,
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (var index = 0; index < exercise.options.length; index++)
                if (!_ordered.contains(index))
                  _AnswerTile(
                    label: exercise.options[index],
                    selected: false,
                    onTap: enabled
                        ? () => setState(() => _ordered.add(index))
                        : null,
                  ),
            ],
          ),
        ];
      case ExerciseKind.match:
        return [
          const Text('Pilih satu kata di kiri, lalu artinya di kanan.'),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(exercise.words.length, (index) {
                    final matched = _pairs.containsKey(index);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _AnswerTile(
                        label: matched
                            ? '${index + 1}. ${exercise.words[index]}'
                            : exercise.words[index],
                        selected: _matchingWord == index || matched,
                        onTap: enabled
                            ? () => setState(() => _matchingWord = index)
                            : null,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(exercise.options.length, (index) {
                    final used = _pairs.entries
                        .where((pair) => pair.value == index)
                        .firstOrNull;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _AnswerTile(
                        label: used == null
                            ? exercise.options[index]
                            : '${used.key + 1}. ${exercise.options[index]}',
                        selected: used != null,
                        onTap: enabled && _matchingWord != null
                            ? () => setState(() {
                                if (used != null) _pairs.remove(used.key);
                                _pairs[_matchingWord!] = index;
                                _matchingWord = null;
                              })
                            : null,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ];
    }
  }

  List<Widget> _summary(BuildContext context, int total) {
    final xp = _earnedXp;
    return [
      const SizedBox(height: 14),
      Center(child: SharkMascot(size: 164, animate: widget.animateMascot)),
      const SizedBox(height: 18),
      Semantics(
        header: true,
        child: Text(
          xp == null ? 'Hati habis' : 'Latihan selesai!',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        xp == null
            ? 'Coba ulangi latihan untuk memulai dengan 5 hati.'
            : '${(_correctCount * 100 / total).round()}% akurat · +$xp XP',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      if (xp == null) ...[
        FilledButton(
          onPressed: () => setState(() {
            _index = 0;
            _hearts = 5;
            _correctCount = 0;
            _clearAnswer();
          }),
          child: const Text('Coba lagi'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: _exit,
          child: const Text('Kembali ke belajar'),
        ),
      ] else
        FilledButton(onPressed: _exit, child: const Text('Kembali ke belajar')),
    ];
  }
}

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          minimumSize: const Size(44, 48),
          backgroundColor: selected ? const Color(0xFFDDEFFE) : Colors.white,
          disabledBackgroundColor: selected
              ? const Color(0xFFDDEFFE)
              : Colors.white,
          disabledForegroundColor: colors.onSurface,
          side: BorderSide(
            color: selected ? colors.primary : const Color(0xFFA3BCCC),
          ),
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.correct, required this.solution});

  final bool correct;
  final String solution;

  @override
  Widget build(BuildContext context) {
    final color = correct ? const Color(0xFF156547) : const Color(0xFFA3203D);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: correct ? const Color(0xFFE2F6ED) : const Color(0xFFFCE6EB),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              correct ? Icons.check_circle_outline : Icons.info_outline,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                correct ? 'Tepat sekali!' : 'Jawaban tepat: $solution',
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
