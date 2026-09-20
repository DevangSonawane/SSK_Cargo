import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_tokens.dart';

/// Liquid-glass Pending / Completed switcher with count badges
/// (Rapido "My Rides" style). A glossy thumb glides fluidly between the
/// segments over a frosted translucent track instead of snapping.
class HistorySegmentBar extends StatelessWidget {
  const HistorySegmentBar({
    super.key,
    required this.upcomingCount,
    required this.completedCount,
    required this.selectedIndex,
    required this.onChanged,
  });

  final int upcomingCount;
  final int completedCount;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const double innerHeight = 44;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SizedBox(
            height: innerHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final segmentWidth = constraints.maxWidth / 2;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      left: selectedIndex == 0 ? 0 : segmentWidth,
                      top: 0,
                      bottom: 0,
                      width: segmentWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white, Color(0xFFEAF3EE)],
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => onChanged(0),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              height: innerHeight,
                              alignment: Alignment.center,
                              child: _SegmentLabel(
                                label: 'Pending',
                                count: upcomingCount,
                                selected: selectedIndex == 0,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => onChanged(1),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              height: innerHeight,
                              alignment: Alignment.center,
                              child: _SegmentLabel(
                                label: 'Completed',
                                count: completedCount,
                                selected: selectedIndex == 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel({
    required this.label,
    required this.count,
    required this.selected,
  });

  final String label;
  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: selected ? AppColors.brandDark : AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.brandTint
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: selected ? AppColors.brandDark : AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

/// Pinned sliver wrapper for [HistorySegmentBar].
///
/// The child is forced to a fixed height ([barHeight] + vertical padding) so
/// the reported sliver extents always match the laid-out child exactly.
/// Guessing the height from font metrics (as before) crashes with
/// "layoutExtent exceeds paintExtent" the moment the numbers drift.
/// The background stays transparent so the frosted bar blurs the list
/// scrolling underneath it.
class HistorySegmentHeaderDelegate extends SliverPersistentHeaderDelegate {
  HistorySegmentHeaderDelegate({
    required this.upcomingCount,
    required this.completedCount,
    required this.selectedIndex,
    required this.onChanged,
  });

  static const double barHeight = 52;
  static const double verticalPadding = 8;
  static const double totalHeight = barHeight + verticalPadding * 2;

  final int upcomingCount;
  final int completedCount;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  double get minExtent => totalHeight;

  @override
  double get maxExtent => totalHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(
        20,
        verticalPadding,
        20,
        verticalPadding,
      ),
      child: SizedBox(
        height: barHeight,
        child: HistorySegmentBar(
          upcomingCount: upcomingCount,
          completedCount: completedCount,
          selectedIndex: selectedIndex,
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant HistorySegmentHeaderDelegate oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.upcomingCount != upcomingCount ||
        oldDelegate.completedCount != completedCount;
  }
}
