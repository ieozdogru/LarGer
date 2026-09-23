import 'package:flutter/material.dart';
import 'package:larger/theme/app_theme.dart';

/// The red wash at the top of History, Today, and Food.
class PageGradient extends StatelessWidget {
  const PageGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x2EE50914),
            AppTheme.primaryBackground,
            AppTheme.primaryBackground,
          ],
          stops: [0, 0.45, 1],
        ),
      ),
    );
  }
}

/// Full-screen gradient behind a transparent scaffold.
class GradientPage extends StatelessWidget {
  const GradientPage({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: PageGradient()),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBar,
          floatingActionButton: floatingActionButton,
          body: body,
        ),
      ],
    );
  }
}
