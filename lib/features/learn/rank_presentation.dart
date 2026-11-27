import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'rank.dart';

class RankShowcase extends StatelessWidget {
  const RankShowcase({super.key, required this.xp, required this.onInfo});

  final int xp;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final rank = rankForXp(xp);
    final next = rank.next;
    final progress = rankProgress(xp);
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF071F38), Color(0xFF103C67), Color(0xFF0D6A8F)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF7DD7EA), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3B075083),
            blurRadius: 22,
            offset: Offset(0, 11),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Stack(
          children: [
            const Positioned(
              right: -58,
              top: -78,
              child: _GlowOrb(size: 230, color: Color(0x2278EBFF)),
            ),
            const Positioned(
              left: -50,
              bottom: -110,
              child: _GlowOrb(size: 190, color: Color(0x1C72CCFF)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFFFFDA86),
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Rank kamu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Lihat semua rank',
                        onPressed: onInfo,
                        icon: const Icon(Icons.info_outline_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 107,
                        height: 107,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              rank.color.withValues(alpha: .56),
                              rank.color.withValues(alpha: .09),
                              Colors.transparent,
                            ],
                          ),
                          border: Border.all(
                            color: rank.color.withValues(alpha: .8),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: rank.color.withValues(alpha: .34),
                              blurRadius: 22,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(child: RankBadge(rank: rank, size: 88)),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TIER ${rank.index + 1} / ${RankTier.values.length}',
                              style: const TextStyle(
                                color: Color(0xFF9FE5F6),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rank.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: rank.color,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '$xp XP terkumpul',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'PROGRES TIER',
                          style: TextStyle(
                            color: Color(0xFFB9E9F5),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      Text(
                        next == null ? 'MAX' : '${(progress * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Semantics(
                    label: 'Progres rank',
                    value: '${(progress * 100).round()} persen',
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF09253E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x667CC9DC)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: progress),
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: value,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [rank.color, const Color(0xFFE8FBFF)],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    next == null
                        ? 'Rank tertinggi tercapai!'
                        : '${next.minXp - xp} XP lagi menuju ${next.label}',
                    style: const TextStyle(
                      color: Color(0xFFD2EEF7),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RankUpDialog extends StatefulWidget {
  const RankUpDialog({
    super.key,
    required this.from,
    required this.to,
    required this.animate,
  });

  final RankTier from;
  final RankTier to;
  final bool animate;

  @override
  State<RankUpDialog> createState() => _RankUpDialogState();
}

class _RankUpDialogState extends State<RankUpDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1050),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.animate || MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (_controller.isDismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    backgroundColor: Colors.transparent,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF092843), Color(0xFF115D83), Color(0xFF092843)],
            ),
            border: Border.all(color: widget.to.color, width: 2),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: widget.to.color.withValues(alpha: .35),
                blurRadius: 35,
                spreadRadius: 3,
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'LEVEL UP!',
                style: TextStyle(
                  color: Color(0xFFB8F3FF),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final t = _controller.value;
                    final pop = Curves.easeOutBack
                        .transform(t)
                        .clamp(0.0, 1.13);
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _VictoryBurst(t, widget.to.color),
                          ),
                        ),
                        Transform.scale(
                          scale: .55 + .45 * pop,
                          child: Transform.rotate(
                            angle: (1 - t) * -.2,
                            child: Container(
                              width: 138,
                              height: 138,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.to.color.withValues(alpha: .18),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.to.color.withValues(
                                      alpha: .48 * t,
                                    ),
                                    blurRadius: 35,
                                    spreadRadius: 7,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: RankBadge(rank: widget.to, size: 112),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Text(
                widget.to.label,
                style: TextStyle(
                  color: widget.to.color,
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.from.label} → ${widget.to.label}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFDCF7FF),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 11),
              const Text(
                'Hebat! Petualanganmu membawa kamu ke tier baru.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.to.color,
                    foregroundColor: const Color(0xFF09233A),
                  ),
                  child: const Text('Lanjut berpetualang'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _VictoryBurst extends CustomPainter {
  const _VictoryBurst(this.progress, this.color);
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (var i = 0; i < 18; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / 18;
      final radius = 30 + progress * (54 + i % 3 * 11);
      final position =
          center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final paint = Paint()
        ..color = (i.isEven ? color : const Color(0xFFB9F5FF)).withValues(
          alpha: (1 - progress * .4).clamp(0.0, 1.0),
        );
      canvas.drawCircle(position, i % 3 == 0 ? 3.8 : 2.3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VictoryBurst oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
