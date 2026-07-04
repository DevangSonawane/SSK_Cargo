import 'package:flutter/material.dart';

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
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x16000000),
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _DriverBottomBarItem(
                label: 'New travel',
                assetPath: 'assets/trucks/new_travel.png',
                selected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DriverBottomBarItem(
                label: 'Active',
                assetPath: 'assets/active.png',
                selected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DriverBottomBarItem(
                label: 'Earnings',
                assetPath: 'assets/earning.png',
                selected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverBottomBarItem extends StatelessWidget {
  const _DriverBottomBarItem({
    required this.label,
    required this.selected,
    required this.onTap,
    this.assetPath,
  });

  final String label;
  final String? assetPath;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = const Color(0xFF1F88C9);
    final iconColor = selected ? selectedColor : const Color(0xFF98A2B3);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Center(
                child: assetPath != null
                    ? Image.asset(
                        assetPath!,
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                        color: iconColor,
                        colorBlendMode: BlendMode.srcIn,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
