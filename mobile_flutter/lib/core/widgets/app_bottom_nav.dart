import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const items = [
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Trang chủ'),
    _NavItem(Icons.school_outlined, Icons.school_rounded, 'Khóa học'),
    _NavItem(Icons.assignment_outlined, Icons.assignment_rounded, 'Kiểm tra'),
    _NavItem(Icons.work_outline_rounded, Icons.work_rounded, 'Ngành'),
    _NavItem(Icons.campaign_outlined, Icons.campaign_rounded, 'Tuyển sinh'),
    _NavItem(Icons.settings_outlined, Icons.settings_rounded, 'Cài đặt'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: RepaintBoundary(
        child: Container(
          height: 66,
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border(context)),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.20)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final selectedWidth = constraints.maxWidth * 0.30;
              final normalWidth =
                  (constraints.maxWidth - selectedWidth) / (items.length - 1);

              return Row(
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final selected = currentIndex == index;
                  final width = selected ? selectedWidth : normalWidth;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeInOutCubic,
                    width: width,
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: currentIndex == index
                            ? null
                            : () => onTap(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeInOutCubic,
                          height: 50,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primaryBlue.withValues(
                                    alpha: isDark ? 0.22 : 0.13,
                                  )
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                            border: selected
                                ? Border.all(
                                    color: AppColors.primaryBlue
                                        .withValues(alpha: 0.16),
                                  )
                                : null,
                          ),
                          child: Center(
                            child: selected
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            item.activeIcon,
                                            color: AppColors.primaryBlue,
                                            size: 21,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            item.label,
                                            maxLines: 1,
                                            softWrap: false,
                                            overflow: TextOverflow.visible,
                                            textScaler: TextScaler.noScaling,
                                            style: TextStyle(
                                              color: AppColors.title(context),
                                              fontSize: 10,
                                              height: 1,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Icon(
                                    item.icon,
                                    color: AppColors.subText(context),
                                    size: 21,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem(this.icon, this.activeIcon, this.label);
}