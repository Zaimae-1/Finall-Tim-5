import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class LearningTabBar extends StatefulWidget {
  const LearningTabBar({
    super.key,
    required this.selectedIndex,
    required this.destinations,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<NavigationDestination> destinations;
  final ValueChanged<int> onSelected;

  @override
  State<LearningTabBar> createState() => _LearningTabBarState();
}

class _LearningTabBarState extends State<LearningTabBar> {
  int? _hoverIndex;
  bool _pointerInside = false;
  int _hoverVisit = 0;

  void _trackHover(double x, double cell, bool rtl) {
    final last = widget.destinations.length - 1;
    final slot = (x / cell).floor().clamp(0, last);
    final index = rtl ? last - slot : slot;
    if (_pointerInside && _hoverIndex == index) return;
    setState(() {
      if (!_pointerInside) _hoverVisit++;
      _pointerInside = true;
      _hoverIndex = index;
    });
  }

  static const _radius = BorderRadius.all(Radius.circular(34));
  static final _blur = ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15);

  @override
  Widget build(BuildContext context) {
    final highContrast = MediaQuery.highContrastOf(context);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              borderRadius: _radius,
              boxShadow: [
                BoxShadow(
                  color: Color(0x24315176),
                  blurRadius: 25,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: _radius,
              child: BackdropFilter(
                filter: _blur,
                enabled: !highContrast,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: _radius,
                    border: Border.all(
                      color: highContrast
                          ? Theme.of(context).colorScheme.onSurface
                          : const Color(0xF7FFFFFF),
                    ),
                    color: highContrast ? Colors.white : null,
                    gradient: highContrast
                        ? null
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xE6FFFFFF), Color(0xBDDEF1FF)],
                          ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: LayoutBuilder(builder: _buildTabs),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context, BoxConstraints constraints) {
    final media = MediaQuery.of(context);
    final colors = Theme.of(context).colorScheme;
    final selectionDuration = media.disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 200);
    final hoverDuration = media.disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 145);
    final textSize = media.textScaler.scale(11);
    final cell = constraints.maxWidth / widget.destinations.length;
    final showLabels = cell >= 48 * textSize / 11;
    final extraHeight = showLabels ? (textSize - 11).clamp(0.0, 20.0) : 0.0;
    final height = (64 + extraHeight).toDouble();
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final stride = rtl ? -cell : cell;
    final hoverIndex = _hoverIndex;

    Color tabColor(Set<WidgetState> states) =>
        states.contains(WidgetState.selected)
        ? colors.primary
        : colors.onSurface;

    return MouseRegion(
      onEnter: (event) => _trackHover(event.localPosition.dx, cell, rtl),
      onHover: (event) => _trackHover(event.localPosition.dx, cell, rtl),
      onExit: (_) => setState(() => _pointerInside = false),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _SlidingPill(
              index: widget.selectedIndex,
              stride: stride,
              height: height - 12,
              duration: selectionDuration,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(27),
                color: media.highContrast ? const Color(0xFFD6E9FC) : null,
                gradient: media.highContrast
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFE5F5FF), Color(0xFFBFDDF9)],
                      ),
                border: Border.all(
                  color: media.highContrast
                      ? colors.primary
                      : const Color(0xECFFFFFF),
                ),
              ),
            ),
            AnimatedOpacity(
              key: const ValueKey('learning-tab-hover'),
              opacity: _pointerInside && hoverIndex != widget.selectedIndex
                  ? 1
                  : 0,
              duration: hoverDuration,
              curve: Curves.easeOut,
              child: hoverIndex == null
                  ? const SizedBox.shrink()
                  : _SlidingPill(
                      key: ValueKey(_hoverVisit),
                      index: hoverIndex,
                      stride: stride,
                      height: height - 12,
                      duration: hoverDuration,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(27),
                        color: media.highContrast
                            ? const Color(0xFFEAF4FC)
                            : null,
                        gradient: media.highContrast
                            ? null
                            : const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xE8FFFFFF), Color(0x9AB7DAF4)],
                              ),
                        border: Border.all(
                          color: media.highContrast
                              ? colors.primary
                              : const Color(0xF5FFFFFF),
                        ),
                      ),
                    ),
            ),
            TooltipVisibility(
              visible: !showLabels,
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  iconTheme: WidgetStateProperty.resolveWith(
                    (states) =>
                        IconThemeData(size: 23, color: tabColor(states)),
                  ),
                ),
                child: NavigationBar(
                  height: height,
                  selectedIndex: widget.selectedIndex,
                  destinations: widget.destinations,
                  onDestinationSelected: widget.onSelected,
                  animationDuration: selectionDuration,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  indicatorColor: Colors.transparent,
                  overlayColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.pressed) ||
                        states.contains(WidgetState.focused)) {
                      return null;
                    }
                    return Colors.transparent;
                  }),
                  elevation: 0,
                  labelPadding: EdgeInsets.zero,
                  labelBehavior: showLabels
                      ? NavigationDestinationLabelBehavior.alwaysShow
                      : NavigationDestinationLabelBehavior.alwaysHide,
                  labelTextStyle: WidgetStateProperty.resolveWith(
                    (states) => TextStyle(
                      color: tabColor(states),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlidingPill extends StatelessWidget {
  const _SlidingPill({
    super.key,
    required this.index,
    required this.stride,
    required this.height,
    required this.duration,
    required this.decoration,
  });

  final int index;
  final double stride;
  final double height;
  final Duration duration;
  final BoxDecoration decoration;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: index.toDouble()),
          duration: duration,
          curve: Curves.easeOutCubic,
          builder: (context, position, child) => Transform.translate(
            offset: Offset(position * stride, 0),
            child: child,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: SizedBox(
              width: stride.abs() - 4,
              height: height,
              child: DecoratedBox(decoration: decoration),
            ),
          ),
        ),
      ),
    );
  }
}
