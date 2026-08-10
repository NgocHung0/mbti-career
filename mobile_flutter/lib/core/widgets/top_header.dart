import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class TopHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;
  final String? badge;
  final Color? badgeColor;

  const TopHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.image,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color safeBadgeColor = badgeColor ?? AppColors.primaryBlue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF111111),
                  const Color(0xFF080808),
                ]
              : [
                  const Color(0xFFEAF6FF),
                  Colors.white,
                ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.22)
                : AppColors.primaryBlue.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF000000) : const Color(0xFFEAF6FF),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border(context)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Image.network(
                image,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, _, _) {
                  return Icon(
                    Icons.image_rounded,
                    color: AppColors.primaryBlue,
                    size: 34,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.title(context),
                    fontSize: 26,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.subText(context),
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: safeBadgeColor.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: safeBadgeColor.withValues(alpha: 0.22)),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  color: safeBadgeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
