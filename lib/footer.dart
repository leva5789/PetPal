import 'package:flutter/material.dart';
import 'chat.dart';
import 'statspage.dart';
import 'milestones_page.dart';
import 'info_page.dart';
import 'homepage.dart';
import 'app_theme.dart';
import 'widgets/premium_widgets.dart';

class Footer extends StatelessWidget {
  final Function(int) onTabSelected;
  final int currentIndex;

  const Footer({
    super.key,
    required this.onTabSelected,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context: context,
            icon: Icons.home_rounded,
            label: 'Home',
            index: 0,
            isDark: isDark,
          ),
          _buildNavItem(
            context: context,
            icon: Icons.chat_bubble_rounded,
            label: 'Chat',
            index: 1,
            isDark: isDark,
          ),
          _buildNavItem(
            context: context,
            icon: Icons.bar_chart_rounded,
            label: 'Stats',
            index: 2,
            isDark: isDark,
          ),
          _buildNavItem(
            context: context,
            icon: Icons.emoji_events_rounded,
            label: 'Milestones',
            index: 3,
            isDark: isDark,
          ),
          _buildNavItem(
            context: context,
            icon: Icons.lightbulb_rounded,
            label: 'Tips',
            index: 4,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required bool isDark,
  }) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (currentIndex == index) return;
        onTabSelected(index);
        _navigateToPage(context, index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.mint.withOpacity(isDark ? 0.2 : 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.mint
                  : (isDark ? Colors.grey[500] : Colors.grey[400]),
              size: isSelected ? 24 : 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.mint,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToPage(BuildContext context, int index) {
    Widget page;
    switch (index) {
      case 0:
        page = HomePage(currentLanguage: 'hu');
        break;
      case 1:
        page = ChatPage();
        break;
      case 2:
        page = StatsPage();
        break;
      case 3:
        page = const MilestonesPage();
        break;
      case 4:
        page = const InfoPage();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }
}
