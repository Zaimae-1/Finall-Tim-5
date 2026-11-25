import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class LearningTabBar extends StatelessWidget {
  const LearningTabBar({
    super.key,
    required this.selectedIndex,
    required this.destinations,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<NavigationDestination> destinations;
  final ValueChanged<int> onSelected;

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
    final duration = media.disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 200);
    final textSize = media.textScaler.scale(11);
    final cell = constraints.maxWidth / destinations.length;
    final showLabels = cell >= 48 * textSize / 11;
    final extraHeight = showLabels ? (textSize - 11).clamp(0.0, 20.0) : 0.0;
    final height = (64 + extraHeight).toDouble();
    final direction = Directionality.of(context) == TextDirection.rtl ? -1 : 1;

    Color tabColor(Set<WidgetState> states) =>
        states.contains(WidgetState.selected)
        ? colors.primary
        : colors.onSurface;

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: selectedIndex.toDouble()),
              duration: duration,
              curve: Curves.easeOutCubic,
              builder: (context, index, child) => Transform.translate(
                offset: Offset(index * cell * direction, 0),
                child: child,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: SizedBox(
                  width: cell - 4,
                  height: height - 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(27),
                      color: media.highContrast
                          ? const Color(0xFFD6E9FC)
                          : null,
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
                ),
              ),
            ),
          ),
          NavigationBarTheme(
            data: NavigationBarThemeData(
              iconTheme: WidgetStateProperty.resolveWith(
                (states) => IconThemeData(size: 23, color: tabColor(states)),
              ),
            ),
            child: NavigationBar(
              height: height,
              selectedIndex: selectedIndex,
              destinations: destinations,
              onDestinationSelected: onSelected,
              animationDuration: duration,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              indicatorColor: Colors.transparent,
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
        ],
      ),
    );
  }
}
