import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:shadcn_ui/shadcn_ui.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/team_model.dart';
import '../../models/user_model.dart';
import '../../models/task_model.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/shadcn/shadcn_widgets.dart';
import '../widgets/add_team_dialog.dart';
import '../widgets/team_members_dialog.dart';

enum TeamTab {
  overview,
  analytics,
  priorities,
  feed,
  team,
  standUp,
  workload,
  timesheet,
}

class TeamDetailPage extends StatefulWidget {
  const TeamDetailPage({super.key, required this.teamId});

  final String teamId;

  @override
  State<TeamDetailPage> createState() => _TeamDetailPageState();
}

class _TeamDetailPageState extends State<TeamDetailPage> {
  TeamTab _activeTab = TeamTab.overview;
  UserModel? _selectedMember;
  bool _isGridView = true;
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'All';
  String _accountTypeFilter = 'All';
  String _managerFilter = 'All';
  String _sortBy = 'Name';
  
  // Workload state
  DateTime _workloadStartDate = DateTime.now();
  String _workloadView = '14 days';
  String _workloadGroupBy = 'Assignee';
  String _workloadTimeEstimate = 'Time Estimates';
  String _workloadScheduleType = 'Daily Scheduled';
  bool _workloadShowClosed = false;
  String _workloadTaskTab = 'Unscheduled';
  
  // Workload filters and search
  final TextEditingController _workloadSearchController = TextEditingController();
  String? _workloadPriorityFilter;
  String? _workloadStatusFilter;
  String? _workloadProjectFilter;
  String _workloadSortBy = 'Status';
  bool _workloadShowSearch = false;
  int _workloadDefaultCapacity = 40;
  
  // Workload backlog state
  bool _showBacklog = false;

  @override
  void initState() {
    super.initState();
    _workloadSearchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _workloadSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        Team? team;
        try {
          team = provider.teams.firstWhere((t) => t.id == widget.teamId);
        } catch (_) {
          team = null;
        }

        if (team == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Team'),
            ),
            body: const Center(child: Text('Team not found')),
          );
        }

        final currentTeam = team;
        final usersById = {
          for (final user in provider.allUsers) user.id: user,
        };
        final members = currentTeam.memberIds
            .map((id) => usersById[id])
            .whereType<UserModel>()
            .toList();

        final filteredMembers = _filterMembers(members);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Row(
            children: [
              // Main content area
              Expanded(
                child: Column(
                  children: [
                    // Top bar with team name and actions
                    _buildTopBar(context, currentTeam, provider),
                    // Tab navigation
                    _buildTabNavigation(),
                    // Search and filters (only for Team tab)
                    if (_activeTab == TeamTab.team) _buildSearchAndFilters(context),
                    // Main content
                    Expanded(
                      child: _buildTabContent(
                        context,
                        currentTeam,
                        provider,
                        filteredMembers,
                      ),
                    ),
                  ],
                ),
              ),
              // Right sidebar for member details
              if (_selectedMember != null)
                _buildMemberSidebar(context, _selectedMember!, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, Team team, DashboardProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
              IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: AppSpacing.md),
          // Team avatar/icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                team.name.isNotEmpty ? team.name[0].toUpperCase() : 'T',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                team.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '@${team.name.toLowerCase().replaceAll(' ', '')}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.edit, size: 20, color: AppColors.textPrimary),
            onPressed: () => _showEditDialog(context, provider, team),
                tooltip: 'Edit team',
              ),
              IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textPrimary),
            onPressed: () => _confirmDelete(context, provider, team),
                tooltip: 'Delete team',
          ),
          const SizedBox(width: AppSpacing.sm),
          AppButton(
            variant: AppButtonVariant.outline,
            onPressed: () => _showMembersDialog(context, provider, team),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_add_alt_1, size: 16),
                SizedBox(width: 4),
                Text('Add member'),
              ],
            ),
          ),
            ],
          ),
    );
  }

  Widget _buildTabNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTabButton(TeamTab.overview, Icons.info_outline, 'Overview'),
                  _buildTabButton(TeamTab.analytics, Icons.bar_chart, 'Analytics'),
                  _buildTabButton(TeamTab.priorities, Icons.flag, 'Priorities'),
                  _buildTabButton(TeamTab.feed, Icons.rss_feed, 'Feed'),
                  _buildTabButton(TeamTab.team, Icons.people, 'Team'),
                  _buildTabButton(TeamTab.standUp, Icons.chat_bubble_outline, 'StandUp'),
                  _buildTabButton(TeamTab.workload, Icons.grid_view, 'Workload'),
                  _buildTabButton(TeamTab.timesheet, Icons.access_time, 'Timesheet'),
                ],
              ),
            ),
          ),
          Consumer<DashboardProvider>(
            builder: (context, provider, _) {
              Team? team;
              try {
                team = provider.teams.firstWhere((t) => t.id == widget.teamId);
              } catch (_) {
                team = null;
              }
              if (team == null) return const SizedBox.shrink();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    onPressed: () {
                      // Export functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Export feature coming soon')),
                      );
                    },
                    child: const Text('Export'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    onPressed: () => _showMembersDialog(context, provider, team!),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_add_alt_1, size: 16),
                        SizedBox(width: 4),
                        Text('Add member'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(TeamTab tab, IconData icon, String label) {
    final isSelected = _activeTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: isMobile
          ? Column(
              children: [
                AppSearchInput(
                  controller: _searchController,
                  placeholder: 'Q Search',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterDropdown('Status', _statusFilter, ['All', 'Active', 'On leave', 'Inactive'], (value) {
                        setState(() => _statusFilter = value);
                      }),
                      const SizedBox(width: AppSpacing.sm),
                      _buildFilterDropdown('Account type', _accountTypeFilter, ['All', 'Member', 'Admin', 'Manager'], (value) {
                        setState(() => _accountTypeFilter = value);
                      }),
                      const SizedBox(width: AppSpacing.sm),
                      _buildFilterDropdown('Sort', _sortBy, ['Name', 'Role', 'Status', 'Join Date'], (value) {
                        setState(() => _sortBy = value);
                      }),
                      const SizedBox(width: AppSpacing.sm),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildViewToggleButton(Icons.grid_view, true),
                          const SizedBox(width: AppSpacing.xs),
                          _buildViewToggleButton(Icons.view_list, false),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: ShadInput(
                    controller: _searchController,
                    placeholder: const Text('Q Search'),
                    leading: const Icon(Icons.search, size: 16, color: AppColors.textMuted),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _buildFilterDropdown('Status', _statusFilter, ['All', 'Active', 'On leave', 'Inactive'], (value) {
                  setState(() => _statusFilter = value);
                }),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterDropdown('Account type', _accountTypeFilter, ['All', 'Member', 'Admin', 'Manager'], (value) {
                  setState(() => _accountTypeFilter = value);
                }),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterDropdown('Manager', _managerFilter, ['All', 'Me', 'Others'], (value) {
                  setState(() => _managerFilter = value);
                }),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterDropdown('Sort', _sortBy, ['Name', 'Role', 'Status', 'Join Date'], (value) {
                  setState(() => _sortBy = value);
                }),
                const SizedBox(width: AppSpacing.sm),
                // View toggle
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewToggleButton(Icons.grid_view, true),
                    const SizedBox(width: AppSpacing.xs),
                    _buildViewToggleButton(Icons.view_list, false),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> options, Function(String) onChanged) {
    return AppSelect<String>(
      placeholder: label,
      value: value,
      options: SelectOption.fromStringList(options),
      selectedOptionBuilder: (context, selectedValue) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              selectedValue ?? value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        );
      },
      onChanged: (selectedValue) {
        if (selectedValue != null) {
          onChanged(selectedValue);
        }
      },
    );
  }

  Widget _buildViewToggleButton(IconData icon, bool isGrid) {
    final isSelected = _isGridView == isGrid;
    return GestureDetector(
      onTap: () => setState(() => _isGridView = isGrid),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? AppColors.primary : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    Team team,
    DashboardProvider provider,
    List<UserModel> members,
  ) {
    switch (_activeTab) {
      case TeamTab.team:
        return _buildTeamTab(context, team, provider, members);
      case TeamTab.overview:
        return _buildOverviewTab(context, team);
      case TeamTab.analytics:
        return _buildAnalyticsTab(context);
      case TeamTab.priorities:
        return _buildPrioritiesTab(context);
      case TeamTab.feed:
        return _buildFeedTab(context);
      case TeamTab.standUp:
        return _buildStandUpTab(context);
      case TeamTab.workload:
        return _buildWorkloadTab(context);
      case TeamTab.timesheet:
        return _buildTimesheetTab(context);
    }
  }

  Widget _buildTeamTab(
    BuildContext context,
    Team team,
    DashboardProvider provider,
    List<UserModel> members,
  ) {
    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No members yet',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              onPressed: () => _showMembersDialog(context, provider, team),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add_alt_1, size: 16),
                  SizedBox(width: 4),
                  Text('Add members'),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: _isGridView
          ? _buildMembersGrid(members)
          : _buildMembersList(members),
    );
  }

  Widget _buildMembersGrid(List<UserModel> members) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 4
            : constraints.maxWidth > 800
                ? 3
                : constraints.maxWidth > 600
                    ? 2
                    : 1;
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.75,
          ),
          itemCount: members.length,
          itemBuilder: (context, index) {
            return _buildMemberCard(members[index], true);
          },
        );
      },
    );
  }

  Widget _buildMembersList(List<UserModel> members) {
    return ListView.builder(
      itemCount: members.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _buildMemberCard(members[index], false),
        );
      },
    );
  }

  Widget _buildMemberCard(UserModel user, bool isGrid) {
    final colors = [
      AppColors.primary,
      const Color(0xFF7C3AED),
      const Color(0xFF059669),
      const Color(0xFFDC2626),
      const Color(0xFFEA580C),
      const Color(0xFF92400E),
    ];
    final colorIndex = user.name.hashCode.abs() % colors.length;
    final avatarColor = colors[colorIndex];
    final isSelected = _selectedMember?.id == user.id;
    final isOnline = user.status == 'Active'; // Simplified online status

    return GestureDetector(
      onTap: () => setState(() => _selectedMember = user),
      child: Container(
        padding: EdgeInsets.all(isGrid ? AppSpacing.lg : AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.border.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: isGrid
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: avatarColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: avatarColor,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.surface,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: avatarColor.withValues(alpha: 0.2),
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: avatarColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.surface,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMemberSidebar(BuildContext context, UserModel user, DashboardProvider provider) {
    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          left: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() => _selectedMember = null),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Row(
                    children: [
                      const Icon(Icons.edit, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Add descript...',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Status
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Tabs
                  Row(
                    children: [
                      _buildSidebarTab('Activity', true),
                      const SizedBox(width: AppSpacing.md),
                      _buildSidebarTab('Tasks (0)', false),
                      const SizedBox(width: AppSpacing.md),
                      _buildSidebarTab('Comments (0)', false),
                      const SizedBox(width: AppSpacing.md),
                      _buildSidebarTab('Calendar', false),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Contact info
                  _buildInfoRow(Icons.email, user.email),
                  const SizedBox(height: AppSpacing.sm),
                  _buildInfoRow(
                    Icons.access_time,
                    '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} ${DateTime.now().hour < 12 ? 'am' : 'pm'} local time',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildInfoRow(Icons.person, 'Select manager'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildInfoRow(Icons.group, user.team ?? 'No team'),
                  const SizedBox(height: AppSpacing.lg),
                  // Priorities
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
                          const SizedBox(width: AppSpacing.xs),
                          const Text(
                            'Priorities',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('+ Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarTab(String label, bool isActive) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? AppColors.primary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // Placeholder tabs
  Widget _buildOverviewTab(BuildContext context, Team team) {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
            'Team Description',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showEditDialog(context, provider, team),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  team.description.isEmpty
                      ? 'Add Team description, information, and wiki'
                      : team.description,
                  style: TextStyle(
                    color: team.description.isEmpty
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Team info section
          Text(
            'Team Information',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
                ),
                const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRowText('Team Name', team.name),
                const SizedBox(height: AppSpacing.sm),
                _buildInfoRowText('Team ID', team.id),
                const SizedBox(height: AppSpacing.sm),
                _buildInfoRowText('Created', _formatDate(team.createdAt)),
                const SizedBox(height: AppSpacing.sm),
                _buildInfoRowText('Members', '${team.memberIds.length}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowText(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildAnalyticsTab(BuildContext context) {
    return const Center(
      child: Text('Analytics coming soon'),
    );
  }

  Widget _buildPrioritiesTab(BuildContext context) {
    return const Center(
      child: Text('Priorities coming soon'),
    );
  }

  Widget _buildFeedTab(BuildContext context) {
    return const Center(
      child: Text('Feed coming soon'),
    );
  }

  Widget _buildStandUpTab(BuildContext context) {
    return const Center(
      child: Text('StandUp coming soon'),
    );
  }

  Widget _buildWorkloadTab(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        Team? team;
        try {
          team = provider.teams.firstWhere((t) => t.id == widget.teamId);
        } catch (_) {
          return const Center(
            child: Text('Team not found'),
          );
        }

        final currentTeam = team;
        final usersById = {for (final user in provider.allUsers) user.id: user};
        final members = currentTeam.memberIds
            .map((id) => usersById[id])
            .whereType<UserModel>()
            .toList();
        
        // Get tasks for team members
        final teamMemberIds = members.map((m) => m.id).toSet();
        var teamTasks = provider.tasks.where((task) => 
          teamMemberIds.contains(task.assignedTo) || task.assignedTo.isEmpty
        ).toList();
        
        // Apply filters
        teamTasks = _filterWorkloadTasks(teamTasks);
        
        // Apply search
        if (_workloadSearchController.text.isNotEmpty) {
          final query = _workloadSearchController.text.toLowerCase();
          teamTasks = teamTasks.where((task) {
            return task.title.toLowerCase().contains(query) ||
                   task.description.toLowerCase().contains(query);
          }).toList();
        }
        
        // Filter closed tasks
        if (!_workloadShowClosed) {
          teamTasks = teamTasks.where((task) => task.status != TaskStatus.completed).toList();
        }
        
        // Calculate date range based on schedule type
        final daysToShow = _getDaysToShow();
        final dates = _generateDates(daysToShow);
        
        if (_showBacklog) {
          return _buildBacklogView(context, teamTasks, members);
        }
        
        return Row(
          children: [
            // Main workload area
                Expanded(
              child: Column(
                children: [
                  // Top controls
                  _buildWorkloadControls(context),
                  // Search bar (if visible)
                  if (_workloadShowSearch)
                    _buildWorkloadSearchBar(context),
                  // Date navigation
                  _buildWorkloadDateNavigation(context, dates),
                  // Calendar grid
                  Expanded(
                    child: _buildWorkloadGrid(context, members, dates, teamTasks, provider),
                  ),
                ],
              ),
            ),
            // Right sidebar for tasks
            _buildWorkloadTaskSidebar(context, teamTasks),
          ],
        );
      },
    );
  }

  Widget _buildWorkloadControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildWorkloadDropdown('Today', _workloadView, ['Today', '7 days', '14 days', '30 days'], (value) {
            setState(() => _workloadView = value);
          }),
          const SizedBox(width: AppSpacing.sm),
          _buildWorkloadDropdown('Time Estimates', _workloadTimeEstimate, ['Time Estimates', 'Hours', 'Days'], (value) {
            setState(() => _workloadTimeEstimate = value);
          }),
          const SizedBox(width: AppSpacing.sm),
          _buildWorkloadDropdown('14 days', _workloadView, ['7 days', '14 days', '30 days'], (value) {
            setState(() => _workloadView = value);
          }),
          const SizedBox(width: AppSpacing.sm),
          _buildWorkloadDropdown('Daily Scheduled', _workloadScheduleType, ['Daily Scheduled', 'Weekly', 'Monthly'], (value) {
            setState(() => _workloadScheduleType = value);
          }),
          const Spacer(),
          _buildWorkloadDropdown('Group: Assignee', _workloadGroupBy, ['Assignee', 'Project', 'Status'], (value) {
            setState(() => _workloadGroupBy = value);
          }),
          const SizedBox(width: AppSpacing.sm),
          AppButton(
            variant: AppButtonVariant.outline,
            onPressed: () => _showWorkloadFilterDialog(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.filter_list, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Filter${_workloadPriorityFilter != null || _workloadStatusFilter != null || _workloadProjectFilter != null ? ' (${[_workloadPriorityFilter, _workloadStatusFilter, _workloadProjectFilter].where((f) => f != null).length})' : ''}',
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _workloadShowClosed
              ? AppButton(
                  onPressed: () {
                    setState(() => _workloadShowClosed = !_workloadShowClosed);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Closed',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : AppButton(
                  variant: AppButtonVariant.outline,
                  onPressed: () {
                    setState(() => _workloadShowClosed = !_workloadShowClosed);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Closed',
                        style: TextStyle(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: Icon(Icons.search, size: 20, color: _workloadShowSearch ? AppColors.primary : AppColors.textMuted),
            onPressed: () {
              setState(() => _workloadShowSearch = !_workloadShowSearch);
            },
            tooltip: 'Search',
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: const Icon(Icons.settings, size: 20),
            onPressed: () => _showWorkloadSettingsDialog(context),
            tooltip: 'Customize',
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: Icon(Icons.book, size: 20, color: _showBacklog ? AppColors.primary : AppColors.textMuted),
            onPressed: () {
              setState(() => _showBacklog = !_showBacklog);
            },
            tooltip: 'Backlog',
          ),
        ],
      ),
    );
  }

  Widget _buildWorkloadDropdown(String label, String value, List<String> options, Function(String) onChanged) {
    return AppSelect<String>(
      placeholder: label,
      value: value,
      options: SelectOption.fromStringList(options),
      selectedOptionBuilder: (context, selectedValue) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            if (selectedValue != null) ...[
              const SizedBox(width: 4),
              Text(
                selectedValue,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        );
      },
      onChanged: (selectedValue) {
        if (selectedValue != null) {
          onChanged(selectedValue);
        }
      },
    );
  }

  Widget _buildWorkloadDateNavigation(BuildContext context, List<DateTime> dates) {
    final startDate = dates.first;
    final endDate = dates.last;
    final now = DateTime.now();
    final currentDay = DateTime(now.year, now.month, now.day);
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: () {
                      setState(() {
                        _workloadStartDate = _workloadStartDate.subtract(Duration(days: dates.length));
                      });
                    },
                  ),
                  Text(
                    '${_formatMonthDay(startDate)} - ${_formatMonthDay(endDate)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: () {
                      setState(() {
                        _workloadStartDate = _workloadStartDate.add(Duration(days: dates.length));
                      });
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.today, size: 20),
                    onPressed: () {
                      setState(() {
                        _workloadStartDate = DateTime.now();
                      });
                    },
                    tooltip: 'Today',
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: () async {
                      final provider = Provider.of<DashboardProvider>(context, listen: false);
                      await _refreshWorkload(provider);
                    },
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ],
          ),
                              const SizedBox(height: AppSpacing.sm),
          // Calendar header
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: 200,
                                child: Text(
                        '${_getMonthName(startDate.month)} ${startDate.year} ${_getMonthName(endDate.month)}',
                                  style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                    Expanded(
                      child: Row(
                        children: dates.map((date) {
                          final isToday = date.year == currentDay.year &&
                              date.month == currentDay.month &&
                              date.day == currentDay.day;
                          
                          return Expanded(
                            child: Column(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isToday ? AppColors.danger.withValues(alpha: 0.1) : Colors.transparent,
                                    border: isToday ? Border.all(color: AppColors.danger, width: 2) : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${_getDayName(date.weekday)}\n${date.day}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                                        color: isToday ? AppColors.danger : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                                if (isToday)
                                  Container(
                                    width: 1,
                                    height: 20,
                                    color: AppColors.danger,
                                    margin: const EdgeInsets.only(top: 4),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkloadGrid(BuildContext context, List<UserModel> members, List<DateTime> dates, List<TaskModel> tasks, DashboardProvider provider) {
    final now = DateTime.now();
    final currentDay = DateTime(now.year, now.month, now.day);
    
    return Row(
      children: [
        // Left pane - Assignees
        Container(
          width: 200,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            border: Border(
              right: BorderSide(
                color: AppColors.border.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
          child: ListView.builder(
            itemCount: members.length + 1, // +1 for unassigned
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildAssigneeRow('unassigned', null, dates, tasks);
              }
              final member = members[index - 1];
              return _buildAssigneeRow(member.name, member, dates, tasks);
                          },
                        ),
                ),
        // Main grid
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: dates.length * 100.0, // Fixed width per date column
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Unassigned row
                  _buildWorkloadRow('unassigned', null, dates, tasks, currentDay, provider),
                  // Member rows
                  ...members.map((member) => _buildWorkloadRow(member.name, member, dates, tasks, currentDay, provider)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssigneeRow(String name, UserModel? member, List<DateTime> dates, List<TaskModel> tasks) {
    final totalHours = _calculateTotalHours(name, member, dates, tasks);
    final capacity = _workloadDefaultCapacity;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (member != null) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: Text(
                member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                style: TextStyle(
                                    color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member != null ? '${member.name.split(' ').map((n) => n[0]).join('')} ${member.name}' : name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_formatHours(totalHours)}/$capacity${_workloadTimeEstimate == 'Days' ? 'd' : 'h'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: totalHours > capacity ? AppColors.danger : AppColors.textMuted,
                    fontWeight: totalHours > capacity ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildWorkloadRow(String name, UserModel? member, List<DateTime> dates, List<TaskModel> tasks, DateTime currentDay, DashboardProvider provider) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: dates.map((date) {
          final isToday = date.year == currentDay.year &&
              date.month == currentDay.month &&
              date.day == currentDay.day;
          final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
          final hours = _calculateHoursForDate(name, member, date, tasks);
          
          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isWeekend ? AppColors.surfaceAlt.withValues(alpha: 0.5) : Colors.transparent,
                border: Border(
                  right: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  left: isToday ? BorderSide(color: AppColors.danger, width: 1) : BorderSide.none,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatHours(hours),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ),
                  ),
                  if (isToday)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 1,
                        color: AppColors.danger,
                      ),
                    ),
                  if (date == dates.last)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.add, size: 12, color: AppColors.primary),
                              onPressed: () => _showAddTaskDialog(context, member, date, provider),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.remove, size: 12, color: AppColors.textMuted),
                              onPressed: () {
                                // TODO: Show dialog to remove scheduled hours
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Remove hours for ${member?.name ?? "Unassigned"} on ${_formatMonthDay(date)}'),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        ),
                ),
              ],
            ),
          ),
        );
        }).toList(),
      ),
    );
  }

  Widget _buildWorkloadTaskSidebar(BuildContext context, List<TaskModel> tasks) {
    final unscheduledTasks = tasks.where((t) => t.status != TaskStatus.completed && t.dueDate.isAfter(DateTime.now().add(const Duration(days: 7)))).toList();
    final overdueTasks = tasks.where((t) => t.dueDate.isBefore(DateTime.now()) && t.status != TaskStatus.completed).toList();
    final noEstimateTasks = tasks.where((t) => true).toList(); // Placeholder
    
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          left: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tasks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.search, size: 18),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 18),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Tabs
          Row(
            children: [
              _buildWorkloadTaskTab('Unscheduled', _workloadTaskTab == 'Unscheduled', () {
                setState(() => _workloadTaskTab = 'Unscheduled');
              }),
              _buildWorkloadTaskTab('No estimate', _workloadTaskTab == 'No estimate', () {
                setState(() => _workloadTaskTab = 'No estimate');
              }),
              _buildWorkloadTaskTab('Overdue', _workloadTaskTab == 'Overdue', () {
                setState(() => _workloadTaskTab = 'Overdue');
              }),
            ],
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Sort Tasks'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: ['Status', 'Priority', 'Due Date', 'Title'].map((sortOption) {
                              return ListTile(
                                title: Text(sortOption),
                                trailing: _workloadSortBy == sortOption
                                    ? const Icon(Icons.check, color: AppColors.primary)
                                    : null,
                                onTap: () {
                                  setState(() => _workloadSortBy = sortOption);
                                  Navigator.of(context).pop();
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sort by $_workloadSortBy',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const Icon(Icons.arrow_upward, size: 14, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: _workloadTaskTab == 'Unscheduled'
                        ? _buildTaskList(_sortTasks(unscheduledTasks))
                        : _workloadTaskTab == 'Overdue'
                            ? _buildTaskList(_sortTasks(overdueTasks))
                            : _buildTaskList(_sortTasks(noEstimateTasks)),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${tasks.length} tasks',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkloadTaskTab(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(List<TaskModel> tasks) {
    if (tasks.isEmpty) {
      return const Center(
        child: Text(
          'No tasks',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      );
    }
    
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            task.title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }

  int _calculateTotalHours(String name, UserModel? member, List<DateTime> dates, List<TaskModel> tasks) {
    int total = 0;
    for (final date in dates) {
      total += _calculateHoursForDate(name, member, date, tasks);
    }
    return total;
  }

  int _calculateHoursForDate(String name, UserModel? member, DateTime date, List<TaskModel> tasks) {
    final memberId = member?.id ?? '';
    
    final dayTasks = tasks.where((task) {
      if (member != null && task.assignedTo != memberId) return false;
      if (member == null && task.assignedTo.isNotEmpty) return false;
      final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      final checkDate = DateTime(date.year, date.month, date.day);
      return taskDate == checkDate;
    }).toList();
    
    // Estimate 2 hours per task (can be improved with actual time estimates)
    return dayTasks.length * 2;
  }

  String _formatMonthDay(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  String _getDayName(int weekday) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[weekday % 7];
  }

  Widget _buildTimesheetTab(BuildContext context) {
    return const Center(
      child: Text('Timesheet coming soon'),
    );
  }

  List<UserModel> _filterMembers(List<UserModel> members) {
    var filtered = members;

    // Search filter
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((user) {
        return user.name.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query);
      }).toList();
    }

    // Status filter
    if (_statusFilter != 'All') {
      filtered = filtered.where((user) => user.status == _statusFilter).toList();
    }

    // Account type filter
    if (_accountTypeFilter != 'All') {
      filtered = filtered.where((user) => user.accountType == _accountTypeFilter).toList();
    }

    // Sort
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'Name':
          return a.name.compareTo(b.name);
        case 'Role':
          return a.role.compareTo(b.role);
        case 'Status':
          return a.status.compareTo(b.status);
        case 'Join Date':
          return b.joinDate.compareTo(a.joinDate);
        default:
          return 0;
      }
    });

    return filtered;
  }

  void _showMembersDialog(
    BuildContext context,
    DashboardProvider provider,
    Team team,
  ) {
    showDialog(
      context: context,
        builder: (context) => TeamMembersDialog(
          team: team,
        users: provider.allUsers,
        onSave: (memberIds) => provider.updateTeamMembers(team.id, memberIds),
      ),
    );
  }

  Future<void> _showEditDialog(
      BuildContext context, DashboardProvider provider, Team team) {
    return showDialog(
      context: context,
      builder: (context) => AddTeamDialog(
        initialTeam: team,
        onSubmit: (updatedTeam) => provider.updateTeam(updatedTeam),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, DashboardProvider provider, Team team) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete team'),
        content: Text('Are you sure you want to delete ${team.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.deleteTeam(team.id);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  // Workload helper methods
  List<TaskModel> _filterWorkloadTasks(List<TaskModel> tasks) {
    var filtered = tasks;
    
    if (_workloadPriorityFilter != null && _workloadPriorityFilter != 'All') {
      final priorityMap = {
        'High': TaskPriority.high,
        'Medium': TaskPriority.medium,
        'Low': TaskPriority.low,
      };
      filtered = filtered.where((task) => 
        task.priority == priorityMap[_workloadPriorityFilter]
      ).toList();
    }
    
    if (_workloadStatusFilter != null && _workloadStatusFilter != 'All') {
      final statusMap = {
        'Pending': TaskStatus.pending,
        'In Progress': TaskStatus.inProgress,
        'Completed': TaskStatus.completed,
      };
      filtered = filtered.where((task) => 
        task.status == statusMap[_workloadStatusFilter]
      ).toList();
    }
    
    // Project filter (using templateId as project identifier for now)
    if (_workloadProjectFilter != null && _workloadProjectFilter != 'All') {
      filtered = filtered.where((task) => 
        task.templateId == _workloadProjectFilter
      ).toList();
    }
    
    return filtered;
  }

  int _getDaysToShow() {
    switch (_workloadScheduleType) {
      case 'Weekly':
        return 7;
      case 'Monthly':
        return 30;
      case 'Daily Scheduled':
      default:
        switch (_workloadView) {
          case 'Today':
            return 1;
          case '7 days':
            return 7;
          case '30 days':
            return 30;
          case '14 days':
          default:
            return 14;
        }
    }
  }

  List<DateTime> _generateDates(int daysToShow) {
    return List.generate(daysToShow, (i) => _workloadStartDate.add(Duration(days: i)));
  }

  Widget _buildWorkloadSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppSearchInput(
              controller: _workloadSearchController,
              placeholder: 'Search tasks...',
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppButton(
            variant: AppButtonVariant.outline,
            onPressed: () {
              setState(() {
                _workloadShowSearch = false;
                _workloadSearchController.clear();
              });
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildBacklogView(BuildContext context, List<TaskModel> tasks, List<UserModel> members) {
    final unscheduledTasks = tasks.where((t) => 
      t.dueDate.isAfter(DateTime.now().add(const Duration(days: 30))) || 
      t.status == TaskStatus.pending
    ).toList();
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(
                color: AppColors.border.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              AppButton(
                variant: AppButtonVariant.outline,
                onPressed: () {
                  setState(() => _showBacklog = false);
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, size: 16),
                    SizedBox(width: 4),
                    Text('Back to Workload'),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Text(
                'Backlog - Unscheduled Tasks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: unscheduledTasks.length,
            itemBuilder: (context, index) {
              final task = unscheduledTasks[index];
              final assignee = members.firstWhere(
                (m) => m.id == task.assignedTo,
                orElse: () => members.isNotEmpty ? members.first : UserModel(
                  id: '',
                  name: 'Unassigned',
                  email: '',
                  role: '',
                  department: 'General',
                  status: 'Active',
                  accountType: 'Employee',
                  joinDate: DateTime.now(),
                ),
              );
              
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task.description.isNotEmpty ? task.description : 'No description',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ShadBadge(
                                child: Text(task.status.name.toUpperCase()),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              ShadBadge(
                                child: Text(task.priority.name.toUpperCase()),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                'Assigned to: ${assignee.name}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AppButton(
                      variant: AppButtonVariant.outline,
                      onPressed: () {
                        // TODO: Open task detail or schedule dialog
                      },
                      child: const Text('Schedule'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showWorkloadFilterDialog(BuildContext context) async {
    String? priorityFilter = _workloadPriorityFilter;
    String? statusFilter = _workloadStatusFilter;
    String? projectFilter = _workloadProjectFilter;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Tasks'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Priority:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              AppSelect<String>(
                placeholder: 'All',
                value: priorityFilter ?? 'All',
                options: SelectOption.fromStringList(['All', 'High', 'Medium', 'Low']),
                selectedOptionBuilder: (context, value) => Text(value ?? 'All'),
                onChanged: (value) => priorityFilter = value,
              ),
              const SizedBox(height: 16),
              const Text('Status:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              AppSelect<String>(
                placeholder: 'All',
                value: statusFilter ?? 'All',
                options: SelectOption.fromStringList(['All', 'Pending', 'In Progress', 'Completed']),
                selectedOptionBuilder: (context, value) => Text(value ?? 'All'),
                onChanged: (value) => statusFilter = value,
              ),
              const SizedBox(height: 16),
              const Text('Project:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              AppSelect<String>(
                placeholder: 'All',
                value: projectFilter ?? 'All',
                options: SelectOption.fromStringList(['All']),
                selectedOptionBuilder: (context, value) => Text(value ?? 'All'),
                onChanged: (value) => projectFilter = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _workloadPriorityFilter = null;
                _workloadStatusFilter = null;
                _workloadProjectFilter = null;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Clear All'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _workloadPriorityFilter = priorityFilter == 'All' ? null : priorityFilter;
                _workloadStatusFilter = statusFilter == 'All' ? null : statusFilter;
                _workloadProjectFilter = projectFilter == 'All' ? null : projectFilter;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _showWorkloadSettingsDialog(BuildContext context) async {
    int capacity = _workloadDefaultCapacity;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Workload Settings'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Default Capacity (hours per week):', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '40',
                ),
                controller: TextEditingController(text: capacity.toString()),
                onChanged: (value) {
                  capacity = int.tryParse(value) ?? 40;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _workloadDefaultCapacity = capacity;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddTaskDialog(BuildContext context, UserModel? member, DateTime date, DashboardProvider provider) async {
    // TODO: Implement quick add task dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quick add task for ${member?.name ?? "Unassigned"} on ${_formatMonthDay(date)}'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _refreshWorkload(DashboardProvider provider) async {
    await provider.refreshTasks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workload refreshed'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  List<TaskModel> _sortTasks(List<TaskModel> tasks) {
    final sorted = List<TaskModel>.from(tasks);
    sorted.sort((a, b) {
      switch (_workloadSortBy) {
        case 'Status':
          return a.status.name.compareTo(b.status.name);
        case 'Priority':
          final priorityOrder = {TaskPriority.high: 0, TaskPriority.medium: 1, TaskPriority.low: 2};
          return (priorityOrder[a.priority] ?? 0).compareTo(priorityOrder[b.priority] ?? 0);
        case 'Due Date':
          return a.dueDate.compareTo(b.dueDate);
        case 'Title':
          return a.title.compareTo(b.title);
        default:
          return 0;
      }
    });
    return sorted;
  }

  String _formatHours(int hours) {
    switch (_workloadTimeEstimate) {
      case 'Days':
        return '${(hours / 8).toStringAsFixed(1)}d';
      case 'Hours':
        return '${hours}h';
      case 'Time Estimates':
      default:
        return '${hours}h';
    }
  }
}
