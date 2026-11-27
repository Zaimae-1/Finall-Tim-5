import 'dart:async';

import 'package:flutter/material.dart';

String formatBoostTime(int remainingMs) {
  final seconds = (remainingMs / 1000).ceil().clamp(0, 5999);
  final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
  final rest = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$rest';
}

/// Live countdown for the running XP booster. Ticks once per second and
/// shows an idle state once the booster has expired.
class BoostCountdown extends StatefulWidget {
  const BoostCountdown({
    super.key,
    required this.percent,
    required this.untilMs,
    this.dark = true,
    this.onExpired,
  });

  final int percent;
  final int? untilMs;
  final bool dark;
  final VoidCallback? onExpired;

  @override
  State<BoostCountdown> createState() => _BoostCountdownState();
}

class _BoostCountdownState extends State<BoostCountdown> {
  Timer? _ticker;

  int get _remaining {
    final until = widget.untilMs;
    if (until == null || widget.percent == 0) return 0;
    final left = until - DateTime.now().millisecondsSinceEpoch;
    return left > 0 ? left : 0;
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant BoostCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (_remaining > 0 && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {});
        if (_remaining == 0) {
          _stop();
          widget.onExpired?.call();
        }
      });
    } else if (_remaining == 0) {
      _stop();
    }
  }

  void _stop() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _remaining;
    final active = remaining > 0;
    final text = widget.dark ? Colors.white : const Color(0xFF103552);
    final muted = widget.dark
        ? const Color(0xFFB9E9F5)
        : const Color(0xFF47647A);
    const gold = Color(0xFFFFDA86);
    final label = active
        ? 'XP Booster +${widget.percent}% aktif, sisa ${formatBoostTime(remaining)}'
        : 'XP Booster tidak aktif';
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: active
              ? gold.withValues(alpha: widget.dark ? .16 : .28)
              : (widget.dark
                    ? const Color(0x1AFFFFFF)
                    : const Color(0xFFE9F2F7)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? gold : const Color(0x557CC9DC),
            width: active ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.bolt_rounded, color: active ? gold : muted, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    active ? 'XP BOOSTER +${widget.percent}%' : 'XP BOOSTER',
                    style: TextStyle(
                      color: active ? gold : muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    active
                        ? 'Bonus XP berlaku selama waktu berjalan'
                        : 'Aktifkan booster dari Toko',
                    style: TextStyle(
                      color: text,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (active)
              Text(
                formatBoostTime(remaining),
                style: TextStyle(
                  color: text,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
