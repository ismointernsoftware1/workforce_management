import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../components/shadcn/shadcn.dart';
import '../utils/animation_utils.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../providers/dashboard_provider.dart';
import '../utils/responsive_utils.dart';
import 'chat/realtime_chat_view.dart';
import 'expenses/expenses_view.dart';
import 'tasks/tasks_view.dart';
import 'team/team_view.dart';
import 'widgets/sidebar.dart';
import '../features/form_builder/screens/form_builder_screen.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  bool _sidebarOpen = true; // Sidebar open by default on web

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        final isMobile = ResponsiveUtils.isMobile(context);
        // On mobile, sidebar is hidden by default (shown via drawer)
        // On desktop, sidebar can be toggled
        final showSidebar = isMobile ? false : _sidebarOpen;
        
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Row(
              children: [
                // Sidebar - show on desktop when open, or use drawer on mobile
                if (showSidebar)
                  Sidebar(
                    activeTab: provider.activeTab,
                    onTabChanged: provider.changeTab,
                  )
                      .animate()
                      .slideX(
                        begin: -1,
                        duration: AnimationUtils.normalDuration,
                        curve: Curves.easeOutCubic,
                      )
                      .fadeIn(duration: AnimationUtils.normalDuration),
                Expanded(
                  child: Column(
                    children: [
                      _TopBar(
                        activeTab: provider.activeTab,
                        onMenuTap: () {
                          if (isMobile) {
                            _showMobileSidebar(context, provider);
                          } else {
                            // Toggle sidebar on web
                            setState(() {
                              _sidebarOpen = !_sidebarOpen;
                            });
                          }
                        },
                      )
                          .animate()
                          .fade(
                            duration: AnimationUtils.normalDuration,
                            delay: AnimationUtils.shortDelay,
                          )
                          .slide(
                            begin: const Offset(0, -10),
                            end: Offset.zero,
                            duration: AnimationUtils.normalDuration,
                            delay: AnimationUtils.shortDelay,
                            curve: Curves.easeOutCubic,
                          ),
                      const SizedBox(height: AppSpacing.sm),
                      if (provider.isLoading)
                        const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.1, 0),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  )),
                                  child: child,
                                ),
                              );
                            },
                            child: _buildTab(provider),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMobileSidebar(BuildContext context, DashboardProvider provider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        alignment: Alignment.centerLeft,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: SizedBox(
          width: 280,
          child: Sidebar(
            activeTab: provider.activeTab,
            onTabChanged: (tab) {
              provider.changeTab(tab);
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTab(DashboardProvider provider) {
    switch (provider.activeTab) {
      case DashboardTab.tasks:
        return TasksView(key: ValueKey('tasks-${provider.activeTab}'));
      case DashboardTab.team:
        return const TeamView(key: ValueKey('team'));
      case DashboardTab.chat:
        return const RealtimeChatView(key: ValueKey('chat'));
      case DashboardTab.expenses:
        return ExpensesView(key: ValueKey('expenses-${provider.activeTab}'));
      case DashboardTab.formBuilder:
        return const FormBuilderScreen(key: ValueKey('form_builder'));
    }
  }
}

class _TopBar extends StatefulWidget {
  const _TopBar({
    required this.activeTab,
    required this.onMenuTap,
  });

  final DashboardTab activeTab;
  final VoidCallback onMenuTap;

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      // Notify the provider about the search query
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      _performSearch(provider, _searchController.text);
    });
  }

  @override
  void didUpdateWidget(_TopBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync search controller with provider when tab changes
    if (oldWidget.activeTab != widget.activeTab) {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      if (widget.activeTab == DashboardTab.tasks) {
        _searchController.text = provider.taskSearchQuery;
      } else if (widget.activeTab == DashboardTab.team) {
        _searchController.clear();
      } else {
        _searchController.clear();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(DashboardProvider provider, String query) {
    switch (widget.activeTab) {
      case DashboardTab.tasks:
        provider.setTaskSearchQuery(query);
        break;
      case DashboardTab.team:
        provider.filterUsers(query);
        break;
      case DashboardTab.chat:
        // Search is handled in ChatView
        break;
      case DashboardTab.expenses:
        // Search is handled in ExpensesView
        break;
      case DashboardTab.formBuilder:
        // No search for form builder
        break;
    }
  }


  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isChat = widget.activeTab == DashboardTab.chat;

    // For Chat tab, we want the chat layout to be truly full-screen with no
    // extra header padding at the top, so we skip rendering this header row.
    if (isChat) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // Always show hamburger menu
          ShadTooltip(
            message: 'Menu',
            child: ShadButton(
              onPressed: widget.onMenuTap,
              variant: ShadButtonVariant.ghost,
              size: ShadButtonSize.icon,
              icon: const Icon(
                Icons.menu,
                size: 24,
                color: AppColors.textPrimary,
              ),
              child: const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: isChat
                // For chat, header and search are handled inside RealtimeChatView's sidebar,
                // so we render an empty placeholder here to keep layout consistent.
                ? const SizedBox.shrink()
                : ShadInput(
                    controller: _searchController,
                    hintText: 'Search...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textMuted,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}


