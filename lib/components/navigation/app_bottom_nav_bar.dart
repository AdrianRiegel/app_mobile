import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.thirdItemIcon = Icons.assignment_outlined,
    this.thirdItemLabel = 'Avaliações',
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final IconData thirdItemIcon;
  final String thirdItemLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.border, width: 1)),
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          selectedItemColor: context.colors.accent,
          unselectedItemColor: context.colors.muted,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: context.colors.surface,
          elevation: 0,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          iconSize: 22,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Início',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              label: 'Turmas',
            ),
            BottomNavigationBarItem(
              icon: Icon(thirdItemIcon),
              label: thirdItemLabel,
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
