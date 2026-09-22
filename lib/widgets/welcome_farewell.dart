import 'package:flutter/material.dart';
import 'package:larger/theme/app_theme.dart';

const welcomeFarewellDuration = Duration(milliseconds: 1100);

/// Covers the app as the welcome questions leave: a red bar opens across
/// the screen, fills it, then fades so the app is underneath.
class WelcomeFarewell extends StatefulWidget {
  const WelcomeFarewell({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<WelcomeFarewell> createState() => _WelcomeFarewellState();
}

class _WelcomeFarewellState extends State<WelcomeFarewell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: welcomeFarewellDuration,
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final bloom = Curves.easeInOutCubic.transform(
          (t / 0.72).clamp(0.0, 1.0),
        );
        final fade = t < 0.62 ? 1.0 : 1 - ((t - 0.62) / 0.38).clamp(0.0, 1.0);
        final size = MediaQuery.sizeOf(context);
        final width = size.width * (bloom / 0.4).clamp(0.0, 1.0);
        final height = bloom < 0.4 ? 3.0 : size.height * ((bloom - 0.4) / 0.6);

        return IgnorePointer(
          ignoring: fade < 0.05,
          child: Opacity(
            opacity: fade,
            child: ColoredBox(
              color: AppTheme.primaryBackground,
              child: Center(
                child: Container(
                  width: width,
                  height: height,
                  color: AppTheme.accentRed,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
