import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:larger/theme/app_theme.dart';

const complicationCalorieColor = AppTheme.accentRed;
const complicationProteinColor = Color(0xFF30D158);
const complicationCarbColor = Color(0xFF64D2FF);

/// One circular complication: a ring, the percent in the middle, and a short label.
class ComplicationRing extends StatelessWidget {
  const ComplicationRing({
    super.key,
    required this.label,
    required this.percent,
    required this.detail,
    required this.color,
  });

  final String label;
  final int? percent;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final value = percent == null ? 0.0 : (percent!.clamp(0, 100)) / 100;
    return Column(
      children: [
        SizedBox(
          width: 92,
          height: 92,
          child: CustomPaint(
            painter: _RingPainter(progress: value, color: color),
            child: Center(
              child: Text(
                percent == null ? '—' : '$percent%',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 22),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 2),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}

class DailyComplications extends StatelessWidget {
  const DailyComplications({
    super.key,
    required this.caloriesEaten,
    required this.calorieTarget,
    required this.proteinEaten,
    required this.proteinGoal,
    required this.carbsEaten,
    required this.carbGoal,
  });

  final int caloriesEaten;
  final int calorieTarget;
  final int proteinEaten;
  final int proteinGoal;
  final int carbsEaten;
  final int carbGoal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ComplicationRing(
            label: 'Calories',
            percent: calorieTarget <= 0
                ? null
                : ((caloriesEaten / calorieTarget) * 100).round(),
            detail: calorieTarget <= 0
                ? '$caloriesEaten kcal'
                : '$caloriesEaten / $calorieTarget',
            color: complicationCalorieColor,
          ),
        ),
        Expanded(
          child: ComplicationRing(
            label: 'Protein',
            percent: proteinGoal <= 0
                ? null
                : ((proteinEaten / proteinGoal) * 100).round(),
            detail: proteinGoal <= 0
                ? '${proteinEaten}g'
                : '$proteinEaten / ${proteinGoal}g',
            color: complicationProteinColor,
          ),
        ),
        Expanded(
          child: ComplicationRing(
            label: 'Carbs',
            percent: carbGoal <= 0
                ? null
                : ((carbsEaten / carbGoal) * 100).round(),
            detail: carbGoal <= 0
                ? '${carbsEaten}g'
                : '$carbsEaten / ${carbGoal}g',
            color: complicationCarbColor,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 8.0;
    final rect = Offset.zero & size;
    final inset = rect.deflate(stroke / 2);
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(inset, 0, math.pi * 2, false, track);
    if (progress <= 0) return;
    canvas.drawArc(inset, -math.pi / 2, math.pi * 2 * progress, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
