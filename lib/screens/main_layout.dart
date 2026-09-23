import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:larger/providers/active_workout_provider.dart';
import 'package:larger/providers/calorie_target_provider.dart';
import 'package:larger/screens/food_screen.dart';
import 'package:larger/screens/history_screen.dart';
import 'package:larger/screens/today_screen.dart';
import 'package:larger/screens/active_workout_screen.dart';
import 'package:larger/screens/welcome_screen.dart';
import 'package:larger/widgets/app_tab_bar.dart';
import 'package:larger/widgets/startup_splash.dart';
import 'package:larger/widgets/welcome_farewell.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  /// History = 0, Today = 1 (default), Food = 2
  int _currentIndex = 1;
  var _splashDone = false;
  late final PageController _pages = PageController(initialPage: 1);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    if (_currentIndex == index) return;
    _pages.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _resumeWorkout() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ActiveWorkoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeWorkout = ref.watch(activeWorkoutProvider);
    final welcomeDone = ref.watch(welcomeCompletedProvider);
    final showWelcome = !welcomeDone;
    final showFarewell = ref.watch(welcomeFarewellProvider);

    final home = Scaffold(
      body: PageView(
        controller: _pages,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: const [
          _KeptPage(child: HistoryScreen()),
          _KeptPage(child: TodayScreen()),
          _KeptPage(child: FoodScreen()),
        ],
      ),
      bottomNavigationBar: AppTabBar(
        selectedIndex: _currentIndex,
        onSelected: _goToPage,
        resume: activeWorkout == null
            ? null
            : WorkoutResumeBar(
                title: activeWorkout.routineName ?? 'Workout in progress',
                onTap: _resumeWorkout,
              ),
      ),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        home,
        if (showWelcome) const WelcomeScreen(),
        if (showFarewell)
          WelcomeFarewell(
            onFinished: () {
              if (mounted) {
                ref.read(welcomeFarewellProvider.notifier).hide();
              }
            },
          ),
        if (!_splashDone)
          StartupSplash(
            onFinished: () {
              if (mounted) setState(() => _splashDone = true);
            },
          ),
      ],
    );
  }
}

class _KeptPage extends StatefulWidget {
  const _KeptPage({required this.child});

  final Widget child;

  @override
  State<_KeptPage> createState() => _KeptPageState();
}

class _KeptPageState extends State<_KeptPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
