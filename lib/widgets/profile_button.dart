import 'package:flutter/material.dart';
import 'package:larger/screens/profile_screen.dart';

class ProfileButton extends StatefulWidget {
  const ProfileButton({super.key, required this.heroTag});

  final String heroTag;

  @override
  State<ProfileButton> createState() => _ProfileButtonState();
}

class _ProfileButtonState extends State<ProfileButton> {
  void _open() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    Navigator.of(context).push<void>(
      reduceMotion
          ? MaterialPageRoute<void>(
              builder: (_) => ProfileScreen(heroTag: widget.heroTag),
            )
          : _ProfileHeroRoute(heroTag: widget.heroTag),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Profile',
      onPressed: _open,
      icon: Hero(
        tag: widget.heroTag,
        createRectTween: profileIconRectTween,
        child: const Material(
          color: Colors.transparent,
          child: Icon(Icons.person_outline, size: 24),
        ),
      ),
    );
  }
}

/// The icon reaches the title first. The rest of the page then drops in.
class _ProfileHeroRoute extends PageRouteBuilder<void> {
  _ProfileHeroRoute({required String heroTag})
    : super(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return ProfileScreen(heroTag: heroTag, entrance: animation);
        },
        transitionDuration: const Duration(milliseconds: 920),
        reverseTransitionDuration: const Duration(milliseconds: 720),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
      );
}
