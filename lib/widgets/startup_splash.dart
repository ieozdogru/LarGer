import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:larger/theme/app_theme.dart';

const startupSplashDuration = Duration(milliseconds: 1600);

/// Brand lockup played on every cold start. It lifts away when it finishes.
class StartupSplash extends StatefulWidget {
  const StartupSplash({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<StartupSplash>
    with SingleTickerProviderStateMixin {
  static const _letters = ['L', 'A', 'R', 'G', 'E', 'R'];

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: startupSplashDuration,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        widget.onFinished();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        widget.onFinished();
        return;
      }
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineLarge?.copyWith(
      fontSize: 64,
      letterSpacing: 2,
      height: 1,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final leave = Curves.easeInCubic.transform(
          ((t - 0.72) / 0.28).clamp(0.0, 1.0),
        );
        final line = Curves.easeOutCubic.transform(
          ((t - 0.12) / 0.34).clamp(0.0, 1.0),
        );

        return Opacity(
          opacity: 1 - leave,
          child: Transform.translate(
            offset: Offset(0, -42 * leave),
            child: ColoredBox(
              color: AppTheme.primaryBackground,
              child: SizedBox.expand(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < _letters.length; i++)
                            _Letter(
                              char: _letters[i],
                              index: i,
                              t: t,
                              style: style,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _RedLine(progress: line),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Letter extends StatelessWidget {
  const _Letter({
    required this.char,
    required this.index,
    required this.t,
    required this.style,
  });

  final String char;
  final int index;
  final double t;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final start = 0.16 + index * 0.055;
    final local = Curves.easeOutCubic.transform(
      ((t - start) / 0.26).clamp(0.0, 1.0),
    );

    return Opacity(
      opacity: local,
      child: Transform.translate(
        offset: Offset(0, 22 * (1 - local)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Text(char, style: style),
        ),
      ),
    );
  }
}

class _RedLine extends StatelessWidget {
  const _RedLine({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final width = 18 + 168 * progress;
    return SizedBox(
      height: 18,
      width: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: width,
              height: 6,
              color: AppTheme.accentRed.withValues(alpha: 0.85 * progress),
            ),
          ),
          Container(
            width: width,
            height: 3,
            color: AppTheme.accentRed.withValues(alpha: progress),
          ),
        ],
      ),
    );
  }
}
