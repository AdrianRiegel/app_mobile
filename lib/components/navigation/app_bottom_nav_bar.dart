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
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.muted,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
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
