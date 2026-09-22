import 'package:flutter/material.dart';
import 'package:larger/screens/profile_screen.dart';

class ProfileButton extends StatelessWidget {
  const ProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Profile',
      onPressed: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
      },
      icon: const Icon(Icons.person_outline),
    );
  }
}
