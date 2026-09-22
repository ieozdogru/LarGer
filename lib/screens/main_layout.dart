import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:larger/providers/active_workout_provider.dart';
import 'package:larger/providers/calorie_target_provider.dart';
import 'package:larger/screens/food_screen.dart';
import 'package:larger/screens/history_screen.dart';
import 'package:larger/screens/today_screen.dart';
import 'package:larger/screens/active_workout_screen.dart';
import 'package:larger/screens/welcome_screen.dart';
import 'package:larger/theme/app_theme.dart';
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

  @override
  Widget build(BuildContext context) {
    final activeWorkout = ref.watch(activeWorkoutProvider);
    final welcomeDone = ref.watch(welcomeCompletedProvider);
    final showWelcome = activeWorkout == null && !welcomeDone;
    final showFarewell = ref.watch(welcomeFarewellProvider);

    final home = activeWorkout != null
        ? const ActiveWorkoutScreen()
        : Scaffold(
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
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _goToPage,
              backgroundColor: AppTheme.surfaceColor,
              indicatorColor: AppTheme.accentRed.withValues(alpha: 0.2),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history, color: AppTheme.accentRed),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.today_outlined),
                  selectedIcon: Icon(Icons.today, color: AppTheme.accentRed),
                  label: 'Today',
                ),
                NavigationDestination(
                  icon: Icon(Icons.restaurant_outlined),
                  selectedIcon: Icon(
                    Icons.restaurant,
                    color: AppTheme.accentRed,
                  ),
                  label: 'Food',
                ),
              ],
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
