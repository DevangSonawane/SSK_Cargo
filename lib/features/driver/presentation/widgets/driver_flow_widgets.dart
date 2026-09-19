import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../../core/theme/app_tokens.dart';

class DriverBottomBar extends StatelessWidget {
  const DriverBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = <_DriverNavItem>[
      const _DriverNavItem(label: 'New travel', icon: LucideIcons.truck),
      const _DriverNavItem(label: 'Active', icon: LucideIcons.book_open_text),
      const _DriverNavItem(label: 'Earnings', icon: LucideIcons.wallet),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(72, 0, 72, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: AppColors.surface.withValues(alpha: 0.72),
                  width: 1.2,
                ),
                boxShadow: AppShadows.float,
              ),
              child: SizedBox(
                height: 58,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth / items.length;
                    const indicatorSize = 50.0;
                    final selectedIndex = currentIndex.clamp(
                      0,
                      items.length - 1,
                    );
                    final left =
                        (itemWidth * selectedIndex) +
                        ((itemWidth - indicatorSize) / 2);

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 360),
                          curve: Curves.easeOutCubic,
                          left: left,
                          top: 4,
                          width: indicatorSize,
                          height: indicatorSize,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.brand,
                              shape: BoxShape.circle,
                              boxShadow: AppShadows.brandGlow,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            for (var index = 0; index < items.length; index++)
                              Expanded(
                                child: _DriverBottomBarItem(
                                  item: items[index],
                                  selected: selectedIndex == index,
                                  onTap: () => onTap(index),
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
        ),
      ),
    );
  }
}

class _DriverNavItem {
  const _DriverNavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _DriverBottomBarItem extends StatelessWidget {
  const _DriverBottomBarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _DriverNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? Colors.white : AppColors.textTertiary;

    return Tooltip(
      message: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: Center(
          child: SizedBox(
            width: 50,
            height: 50,
            child: AnimatedScale(
              scale: selected ? 1.14 : 1,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              child: Icon(item.icon, size: 22, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}
