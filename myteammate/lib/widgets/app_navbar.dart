import 'package:flutter/material.dart';

class AppNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppNavBar({super.key, required this.currentIndex, required this.onTap});

  static const _itemCount = 5;
  static const _circleSize = 44.0;

  double _itemCenter(int index, double totalWidth) =>
      totalWidth * (2 * index + 1) / (2 * _itemCount);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final circleX = _itemCenter(currentIndex, constraints.maxWidth);
        return Container(
          height: 68,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 153, 209, 138),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left: circleX - _circleSize / 2,
                top: (68 - _circleSize) / 2,
                child: Container(
                  width: _circleSize,
                  height: _circleSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A5A3A).withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    index: 0,
                    currentIndex: currentIndex,
                    onTap: onTap,
                  ),
                  _NavItem(
                    icon: Icons.search,
                    activeIcon: Icons.search,
                    index: 1,
                    currentIndex: currentIndex,
                    onTap: onTap,
                  ),
                  _CenterButton(
                    isActive: currentIndex == 2,
                    onTap: () => onTap(2),
                  ),
                  _NavItem(
                    icon: Icons.notifications_outlined,
                    activeIcon: Icons.notifications,
                    index: 3,
                    currentIndex: currentIndex,
                    onTap: onTap,
                  ),
                  _NavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    index: 4,
                    currentIndex: currentIndex,
                    onTap: onTap,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 68,
        child: Center(
          child: Icon(
            isActive ? activeIcon : icon,
            size: 26,
            color: isActive ? const Color(0xFF3A5A3A) : const Color(0xFF5A5A5A),
          ),
        ),
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _CenterButton({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF4A7A4A)
              : const Color.fromARGB(255, 103, 143, 92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.menu,
          size: 26,
          color: isActive ? Colors.white : const Color(0xFF3A3A3A),
        ),
      ),
    );
  }
}
