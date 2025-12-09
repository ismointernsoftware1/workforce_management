import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../providers/dashboard_provider.dart';

/// Mobile Bottom Navigation Bar
class MobileBottomNav extends StatelessWidget {
  const MobileBottomNav({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
    this.availableTabs,
  });

  final DashboardTab currentTab;
  final ValueChanged<DashboardTab> onTabChanged;
  final List<DashboardTab>? availableTabs;

  @override
  Widget build(BuildContext context) {
    // Default tabs if not provided
    final tabs = availableTabs ?? [
      DashboardTab.tasks,
      DashboardTab.team,
      DashboardTab.chat,
      DashboardTab.expenses,
      DashboardTab.roles,
    ];

    // Map tabs to bottom nav items (max 5 items)
    final navItems = tabs.take(5).map((tab) {
      return _NavItemData(
        tab: tab,
        icon: _getIcon(tab),
        activeIcon: _getActiveIcon(tab),
        label: _getLabel(tab),
        isActive: currentTab == tab,
      );
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.map((item) {
              return _NavItem(
                icon: item.icon,
                activeIcon: item.activeIcon,
                label: item.label,
                isActive: item.isActive,
                onTap: () => onTabChanged(item.tab),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(DashboardTab tab) {
    switch (tab) {
      case DashboardTab.tasks:
        return Icons.dashboard_customize_outlined;
      case DashboardTab.team:
        return Icons.people_outline;
      case DashboardTab.chat:
        return Icons.chat_bubble_outline;
      case DashboardTab.expenses:
        return Icons.receipt_long_outlined;
      case DashboardTab.roles:
        return Icons.shield_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  IconData _getActiveIcon(DashboardTab tab) {
    switch (tab) {
      case DashboardTab.tasks:
        return Icons.dashboard_customize;
      case DashboardTab.team:
        return Icons.people;
      case DashboardTab.chat:
        return Icons.chat_bubble;
      case DashboardTab.expenses:
        return Icons.receipt_long;
      case DashboardTab.roles:
        return Icons.shield;
      default:
        return Icons.circle;
    }
  }

  String _getLabel(DashboardTab tab) {
    switch (tab) {
      case DashboardTab.tasks:
        return 'Tasks';
      case DashboardTab.team:
        return 'Team';
      case DashboardTab.chat:
        return 'Chat';
      case DashboardTab.expenses:
        return 'Expenses';
      case DashboardTab.roles:
        return 'Roles';
      default:
        return 'Tab';
    }
  }
}

class _NavItemData {
  const _NavItemData({
    required this.tab,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
  });

  final DashboardTab tab;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                size: 24,
                color: isActive ? AppColors.primary : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: isActive ? 24 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

