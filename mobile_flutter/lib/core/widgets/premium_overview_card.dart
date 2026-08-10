import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class PremiumAbilityItem {
  final String title;
  final double percent;

  const PremiumAbilityItem({
    required this.title,
    required this.percent,
  });
}

class PremiumOverviewCard extends StatelessWidget {
  final String mbti;

  final Map<String, double> interests;
  final Map<String, double> abilities;

  const PremiumOverviewCard({
    super.key,
    required this.mbti,
    required this.interests,
    required this.abilities,
  });

  static const Color blue = Color(0xFF1686E8);
  static const Color purple = Color(0xFF7137D8);

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final interestItems = <_ProfileSegment>[
      _ProfileSegment(
        label: 'Phân tích -\nCông nghệ',
        value: _readValue(
          interests,
          ['analytic'],
        ),
      ),
      _ProfileSegment(
        label: 'Kinh doanh -\nTổ chức',
        value: _readValue(
          interests,
          ['business'],
        ),
      ),
      _ProfileSegment(
        label: 'Con người -\nGiao tiếp',
        value: _readValue(
          interests,
          ['social'],
        ),
      ),
      _ProfileSegment(
        label: 'Sáng tạo',
        value: _readValue(
          interests,
          ['creative'],
        ),
      ),
    ];

    final abilityItems = <_ProfileSegment>[
      _ProfileSegment(
        label: 'Ngôn ngữ',
        value: _readValue(
          abilities,
          ['LANGUAGE'],
        ),
      ),
      _ProfileSegment(
        label: 'Tư duy logic',
        value: _readValue(
          abilities,
          ['LOGIC'],
        ),
      ),
      _ProfileSegment(
        label: 'Sáng tạo',
        value: _readValue(
          abilities,
          ['CREATIVE'],
        ),
      ),
      _ProfileSegment(
        label: 'Công nghệ',
        value: _readValue(
          abilities,
          ['TECH'],
        ),
      ),
      _ProfileSegment(
        label: 'Lãnh đạo',
        value: _readValue(
          abilities,
          ['LEADERSHIP'],
        ),
      ),
      _ProfileSegment(
        label: 'Làm việc nhóm',
        value: _readValue(
          abilities,
          ['TEAMWORK'],
        ),
      ),
      _ProfileSegment(
        label: 'Chi tiết -\nCẩn thận',
        value: _readValue(
          abilities,
          ['DETAIL'],
        ),
      ),
      _ProfileSegment(
        label: 'Thích nghi',
        value: _readValue(
          abilities,
          ['ADAPT'],
        ),
      ),
      _ProfileSegment(
        label: 'Thực hành',
        value: _readValue(
          abilities,
          ['PRACTICAL'],
        ),
      ),
      _ProfileSegment(
        label: 'Chiến lược',
        value: _readValue(
          abilities,
          ['STRATEGIC'],
        ),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        22,
        20,
        20,
      ),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.border(context),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng quan hồ sơ của bạn',
            style: TextStyle(
              color: AppColors.title(context),
              fontSize: 24,
              height: 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 18),

          const Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _LegendItem(
                color: Color(0xFF2E98F0),
                label: 'Sở thích (4 tiêu chí)',
              ),
              _LegendItem(
                color: Color(0xFF7D45DE),
                label: 'Năng lực (10 tiêu chí)',
              ),
            ],
          ),

          const SizedBox(height: 10),

          LayoutBuilder(
            builder: (context, constraints) {
              final chartSize = math.min(
                constraints.maxWidth,
                390.0,
              );

              return Center(
                child: SizedBox.square(
                  dimension: chartSize,
                  child: CustomPaint(
                    painter: _ProfileWheelPainter(
                      mbti: mbti,
                      interests: interestItems,
                      abilities: abilityItems,
                      isDark: isDark,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF10243A)
                  : const Color(0xFFF3F9FF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF234B73)
                    : const Color(0xFFB9DEFF),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: blue,
                      width: 2.4,
                    ),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: blue,
                    size: 21,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    'Tỷ lệ càng cao thể hiện mức độ bạn có sở thích hoặc năng lực mạnh hơn ở tiêu chí đó.',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF8CC8FF)
                          : const Color(0xFF347CC5),
                      fontSize: 14.5,
                      height: 1.45,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static double _readValue(
    Map<String, double> source,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = source[key];

      if (value != null) {
        return value.clamp(0, 100).toDouble();
      }
    }

    return 0;
  }
}

class PremiumTopAbilitiesCard extends StatelessWidget {
  final bool loading;
  final List<PremiumAbilityItem> items;

  const PremiumTopAbilitiesCard({
    super.key,
    required this.loading,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(3).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        22,
        20,
        20,
      ),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.border(context),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top năng lực nổi trội',
            style: TextStyle(
              color: AppColors.title(context),
              fontSize: 24,
              height: 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            '3 năng lực có tỷ lệ nổi bật cao nhất',
            style: TextStyle(
              color: AppColors.subText(context),
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 16),

          if (loading && visibleItems.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 22,
                ),
                child: CircularProgressIndicator(),
              ),
            )
          else
            ...List.generate(
              visibleItems.length,
              (index) {
                final item = visibleItems[index];

                return Padding(
                  padding: EdgeInsets.only(
                    bottom:
                        index == visibleItems.length - 1
                            ? 0
                            : 11,
                  ),
                  child: _AbilityRankRow(
                    rank: index + 1,
                    item: item,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 8),

        Text(
          label,
          style: TextStyle(
            color: AppColors.subText(context),
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _AbilityRankRow extends StatelessWidget {
  final int rank;
  final PremiumAbilityItem item;

  const _AbilityRankRow({
    required this.rank,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    List<Color> badgeColors;

    Color percentColor;

    if (rank == 1) {
      badgeColors = const [
        Color(0xFF6F2DDB),
        Color(0xFFA956F2),
      ];

      percentColor = const Color(0xFF7030D8);
    } else if (rank == 2) {
      badgeColors = const [
        Color(0xFF0877E8),
        Color(0xFF35B3FF),
      ];

      percentColor = const Color(0xFF0877E8);
    } else {
      badgeColors = const [
        Color(0xFFFF7900),
        Color(0xFFFFB331),
      ];

      percentColor = const Color(0xFFF07800);
    }

   return Container(
    constraints: const BoxConstraints(
      minHeight: 66,
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: 13,
      vertical: 10,
    ),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: rank == 1
              ? const Color(0xFFC69CF7)
              : AppColors.border(context),
          width: rank == 1 ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: badgeColors,
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              '#$rank',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.title(context),
                fontSize: 16,
                height: 1.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Text(
            _formatPercent(item.percent),
            style: TextStyle(
              color: percentColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSegment {
  final String label;
  final double value;

  const _ProfileSegment({
    required this.label,
    required this.value,
  });
}

class _ProfileWheelPainter extends CustomPainter {
  final String mbti;
  final List<_ProfileSegment> interests;
  final List<_ProfileSegment> abilities;
  final bool isDark;

  const _ProfileWheelPainter({
    required this.mbti,
    required this.interests,
    required this.abilities,
    required this.isDark,
  });

  static const Color blue = Color(0xFF1686E8);
  static const Color purple = Color(0xFF7137D8);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius =
        math.min(size.width, size.height) / 2;

    final outerRadius = radius * 0.94;
    final outerInnerRadius = radius * 0.63;

    final interestOuterRadius = radius * 0.61;
    final interestInnerRadius = radius * 0.29;

    final centerRadius = radius * 0.275;

    final outerFill = isDark
        ? const Color(0xFF251A3B)
        : const Color(0xFFF2EBFF);

    final interestFill = isDark
        ? const Color(0xFF142B42)
        : const Color(0xFFE8F5FF);

    final divider = isDark
        ? const Color(0xFF111111)
        : Colors.white;

    final titleColor = isDark
        ? const Color(0xFFEAF6FF)
        : const Color(0xFF0E2A54);

    final centerFill = isDark
        ? const Color(0xFF151515)
        : Colors.white;

    _drawSegmentRing(
      canvas: canvas,
      center: center,
      outerRadius: outerRadius,
      innerRadius: outerInnerRadius,
      itemCount: abilities.length,
      startAngle: _degrees(-108),
      fillColor: outerFill,
      dividerColor: divider,
      dividerWidth: radius * 0.018,
    );

    _drawSegmentRing(
      canvas: canvas,
      center: center,
      outerRadius: interestOuterRadius,
      innerRadius: interestInnerRadius,
      itemCount: interests.length,
      startAngle: _degrees(-90),
      fillColor: interestFill,
      dividerColor: divider,
      dividerWidth: radius * 0.025,
    );

    _drawProgressArcs(
      canvas: canvas,
      center: center,
      radius: outerRadius + radius * 0.025,
      segments: abilities,
      startAngle: _degrees(-108),
      color: purple,
      strokeWidth: radius * 0.035,
      gapAngle: _degrees(7),
    );

    _drawProgressArcs(
      canvas: canvas,
      center: center,
      radius:
          interestOuterRadius + radius * 0.02,
      segments: interests,
      startAngle: _degrees(-90),
      color: blue,
      strokeWidth: radius * 0.028,
      gapAngle: _degrees(6),
    );

    canvas.drawCircle(
      center,
      centerRadius,
      Paint()
        ..color = centerFill
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      center,
      centerRadius,
      Paint()
        ..color = isDark
            ? const Color(0xFF38465B)
            : const Color(0xFFDCE7F1)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke,
    );

    _drawCenterText(
      canvas,
      center,
      centerRadius,
      titleColor,
    );

    _drawSegmentTexts(
      canvas: canvas,
      center: center,
      segments: interests,
      startAngle: _degrees(-90),
      radius:
          (interestOuterRadius +
                  interestInnerRadius) /
              2,
      labelColor: titleColor,
      valueColor: blue,
      maxWidth: radius * 0.46,
      labelSize: radius * 0.052,
      valueSize: radius * 0.072,
    );

    _drawSegmentTexts(
      canvas: canvas,
      center: center,
      segments: abilities,
      startAngle: _degrees(-108),
      radius:
          (outerRadius + outerInnerRadius) /
              2,
      labelColor: titleColor,
      valueColor: purple,
      maxWidth: radius * 0.35,
      labelSize: radius * 0.041,
      valueSize: radius * 0.062,
    );
  }

  void _drawSegmentRing({
    required Canvas canvas,
    required Offset center,
    required double outerRadius,
    required double innerRadius,
    required int itemCount,
    required double startAngle,
    required Color fillColor,
    required Color dividerColor,
    required double dividerWidth,
  }) {
    if (itemCount == 0) return;

    final sweep =
        math.pi * 2 / itemCount;

    for (var index = 0;
        index < itemCount;
        index++) {
      final path = _ringSectorPath(
        center: center,
        outerRadius: outerRadius,
        innerRadius: innerRadius,
        startAngle:
            startAngle + sweep * index,
        sweepAngle: sweep,
      );

      canvas.drawPath(
        path,
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill,
      );

      canvas.drawPath(
        path,
        Paint()
          ..color = dividerColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = dividerWidth
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  void _drawProgressArcs({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required List<_ProfileSegment> segments,
    required double startAngle,
    required Color color,
    required double strokeWidth,
    required double gapAngle,
  }) {
    if (segments.isEmpty) return;

    final segmentSweep =
        math.pi * 2 / segments.length;

    for (var index = 0;
        index < segments.length;
        index++) {
      final value =
          segments[index]
              .value
              .clamp(0, 100) /
          100;

      if (value <= 0) continue;

      final availableSweep =
          segmentSweep - gapAngle;

      final progressSweep =
          availableSweep * value;

      final baseStart =
          startAngle +
          segmentSweep * index +
          gapAngle / 2;

      final progressStart =
          baseStart +
          (availableSweep - progressSweep) /
              2;

      canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        progressStart,
        progressSweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawSegmentTexts({
    required Canvas canvas,
    required Offset center,
    required List<_ProfileSegment> segments,
    required double startAngle,
    required double radius,
    required Color labelColor,
    required Color valueColor,
    required double maxWidth,
    required double labelSize,
    required double valueSize,
  }) {
    if (segments.isEmpty) return;

    final sweep =
        math.pi * 2 / segments.length;

    for (var index = 0;
        index < segments.length;
        index++) {
      final angle =
          startAngle +
          sweep * (index + 0.5);

      final point = Offset(
        center.dx +
            math.cos(angle) * radius,
        center.dy +
            math.sin(angle) * radius,
      );

      final labelPainter = TextPainter(
        text: TextSpan(
          text: segments[index].label,
          style: TextStyle(
            color: labelColor,
            fontSize: labelSize,
            height: 1.08,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 2,
      )..layout(maxWidth: maxWidth);

      final valuePainter = TextPainter(
        text: TextSpan(
          text: _formatPercent(
            segments[index].value,
          ),
          style: TextStyle(
            color: valueColor,
            fontSize: valueSize,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: maxWidth);

      final totalHeight =
          labelPainter.height +
          valuePainter.height +
          3;

      final top =
          point.dy - totalHeight / 2;

      labelPainter.paint(
        canvas,
        Offset(
          point.dx -
              labelPainter.width / 2,
          top,
        ),
      );

      valuePainter.paint(
        canvas,
        Offset(
          point.dx -
              valuePainter.width / 2,
          top +
              labelPainter.height +
              3,
        ),
      );
    }
  }

  void _drawCenterText(
    Canvas canvas,
    Offset center,
    double centerRadius,
    Color titleColor,
  ) {
    final typePainter = TextPainter(
      text: TextSpan(
        text: mbti.trim().toUpperCase(),
        style: TextStyle(
          color: titleColor,
          fontSize: centerRadius * 0.47,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(
        maxWidth: centerRadius * 1.7,
      );

    final subtitlePainter =
        TextPainter(
      text: TextSpan(
        text: 'Hồ sơ tổng hợp',
        style: TextStyle(
          color: isDark
              ? const Color(0xFF9AA8BA)
              : const Color(0xFF657891),
          fontSize: centerRadius * 0.19,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(
        maxWidth: centerRadius * 1.75,
      );

    final top =
        center.dy -
        (typePainter.height +
                subtitlePainter.height +
                5) /
            2;

    typePainter.paint(
      canvas,
      Offset(
        center.dx -
            typePainter.width / 2,
        top,
      ),
    );

    subtitlePainter.paint(
      canvas,
      Offset(
        center.dx -
            subtitlePainter.width / 2,
        top +
            typePainter.height +
            5,
      ),
    );
  }

  Path _ringSectorPath({
    required Offset center,
    required double outerRadius,
    required double innerRadius,
    required double startAngle,
    required double sweepAngle,
  }) {
    final outerRect = Rect.fromCircle(
      center: center,
      radius: outerRadius,
    );

    final innerRect = Rect.fromCircle(
      center: center,
      radius: innerRadius,
    );

    return Path()
      ..arcTo(
        outerRect,
        startAngle,
        sweepAngle,
        false,
      )
      ..arcTo(
        innerRect,
        startAngle + sweepAngle,
        -sweepAngle,
        false,
      )
      ..close();
  }

  static double _degrees(double value) {
    return value * math.pi / 180;
  }

  @override
  bool shouldRepaint(
    covariant _ProfileWheelPainter oldDelegate,
  ) {
    return true;
  }
}

String _formatPercent(double value) {
  final safe =
      value.clamp(0, 100).toDouble();

  if ((safe - safe.round()).abs() < 0.05) {
    return '${safe.round()}%';
  }

  return '${safe.toStringAsFixed(1)}%';
}