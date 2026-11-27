import 'package:flutter/material.dart';

import 'rank.dart';

class RankListSheet extends StatefulWidget {
  const RankListSheet({super.key, required this.current});

  final RankTier current;

  @override
  State<RankListSheet> createState() => _RankListSheetState();
}

class _RankListSheetState extends State<RankListSheet> {
  RankTier? _selected;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * .82;
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF071D34), Color(0xFF103C5E), Color(0xFF08263F)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF8CBFD2),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFFFFD687),
                      size: 26,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Daftar semua rank',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 13),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Ketuk lencana untuk melihat jalur XP.',
                    style: TextStyle(color: Color(0xFFB2D8E7)),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                  itemCount: RankTier.values.length,
                  itemBuilder: (context, index) {
                    final tier = RankTier.values[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TierCard(
                        tier: tier,
                        current: tier == widget.current,
                        selected: tier == _selected,
                        onTap: () => setState(
                          () => _selected = _selected == tier ? null : tier,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 15),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB7EDFF),
                      foregroundColor: const Color(0xFF08243B),
                    ),
                    child: const Text('Tutup'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.tier,
    required this.current,
    required this.selected,
    required this.onTap,
  });

  final RankTier tier;
  final bool current;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final range = tier.next == null
        ? '${tier.minXp}+ XP'
        : '${tier.minXp}–${tier.next!.minXp - 1} XP';
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tier.color.withValues(alpha: selected ? .37 : .24),
            const Color(0xFF143F5F),
            const Color(0xFF09263F),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tier.color.withValues(alpha: selected ? .95 : .54),
          width: selected ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: tier.color.withValues(alpha: selected ? .25 : .12),
            blurRadius: selected ? 17 : 9,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tier.color.withValues(alpha: .13),
                        boxShadow: [
                          BoxShadow(
                            color: tier.color.withValues(alpha: .25),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                      child: Center(child: RankBadge(rank: tier, size: 54)),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  tier.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: tier.color,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              if (current) ...[
                                const SizedBox(width: 7),
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF8DE9CD),
                                  size: 18,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            range,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      selected
                          ? Icons.expand_less_rounded
                          : Icons.chevron_right_rounded,
                      color: const Color(0xFFBDDAE8),
                    ),
                  ],
                ),
                if (selected) ...[
                  const SizedBox(height: 10),
                  Divider(color: tier.color.withValues(alpha: .38)),
                  Text(
                    tier.next == null
                        ? 'Tier tertinggi. Kumpulkan XP sebanyak mungkin!'
                        : 'Mulai pada ${tier.minXp} XP. ${tier.next!.minXp} XP membuka ${tier.next!.label}.',
                    style: const TextStyle(
                      color: Color(0xFFD7EDF5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
