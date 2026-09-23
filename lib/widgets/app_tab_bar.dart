import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:larger/theme/app_theme.dart';

class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.resume,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget? resume;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottom > 0 ? bottom : 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (resume != null) ...[resume!, const SizedBox(height: 8)],
          _Glass(
            child: Row(
              children: [
                _Tab(
                  label: 'History',
                  icon: Icons.history_outlined,
                  selectedIcon: Icons.history,
                  selected: selectedIndex == 0,
                  onTap: () => onSelected(0),
                ),
                _Tab(
                  label: 'Today',
                  icon: Icons.today_outlined,
                  selectedIcon: Icons.today,
                  selected: selectedIndex == 1,
                  onTap: () => onSelected(1),
                ),
                _Tab(
                  label: 'Food',
                  icon: Icons.restaurant_outlined,
                  selectedIcon: Icons.restaurant,
                  selected: selectedIndex == 2,
                  onTap: () => onSelected(2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WorkoutResumeBar extends StatelessWidget {
  const WorkoutResumeBar({super.key, required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.fitness_center,
                color: AppTheme.accentRed,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Text(
                'Resume',
                style: TextStyle(
                  color: AppTheme.accentRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.accentRed : Colors.white54;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? selectedIcon : icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white54,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: selected ? 16 : 0,
                height: 2,
                decoration: BoxDecoration(
                  color: AppTheme.accentRed,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
