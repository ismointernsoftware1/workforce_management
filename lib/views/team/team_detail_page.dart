import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:shadcn_ui/shadcn_ui.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/team_model.dart';
import '../../models/user_model.dart';
import '../../models/task_model.dart';
import '../../models/timesheet_entry.dart';
import '../../providers/dashboard_provider.dart';
import '../../services/firebase_service.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/shadcn/shadcn_widgets.dart';
import '../../widgets/shadcn/app_button.dart';
import '../widgets/add_team_dialog.dart';
import '../widgets/team_members_dialog.dart';

enum TeamTab {
  overview,
  team,
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
  bool _isGridView = true;
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'All';
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
  
  // Timesheet state
  DateTime _timesheetStartDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _timesheetEndDate = DateTime.now();
  List<TimesheetEntry> _timesheetEntries = [];
  bool _isLoadingTimesheet = false;
  String? _editingEntryId;
  String? _editingUserId;
  DateTime? _editingDate;

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = ResponsiveUtils.isMobile(context);
          
          if (isMobile) {
            // Mobile: Stack vertically or use menu
            return Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: AppSpacing.xs),
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
                const SizedBox(width: AppSpacing.xs),
                // Team name - flexible to prevent overflow
                Expanded(
                  child: Column(
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
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        '@${team.name.toLowerCase().replaceAll(' ', '')}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                // Menu button for actions on mobile
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditDialog(context, provider, team);
                    } else if (value == 'delete') {
                      _confirmDelete(context, provider, team);
                    } else if (value == 'add_member') {
                      _showMembersDialog(context, provider, team);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'add_member',
                      child: Row(
                        children: [
                          Icon(Icons.person_add_alt_1, size: 18),
                          SizedBox(width: 8),
                          Text('Add member'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit team'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                          SizedBox(width: 8),
                          Text('Delete team', style: TextStyle(color: AppColors.danger)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          } else {
            // Desktop/Tablet: Full horizontal layout
            return Row(
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
                // Team name - flexible to prevent overflow
                Flexible(
                  child: Column(
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
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        '@${team.name.toLowerCase().replaceAll(' ', '')}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
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
            );
          }
        },
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
                  _buildTabButton(TeamTab.team, Icons.people, 'Team'),
                  _buildTabButton(TeamTab.workload, Icons.grid_view, 'Workload'),
                  _buildTabButton(TeamTab.timesheet, Icons.access_time, 'Timesheet'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(TeamTab tab, IconData icon, String label) {
    final isSelected = _activeTab == tab;
    return GestureDetector(
      onTap: () {
        setState(() => _activeTab = tab);
        if (tab == TeamTab.timesheet) {
          _loadTimesheetEntries();
        }
      },
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
                      _buildFilterDropdown('Sort', _sortBy, ['Name', 'Role', 'Status'], (value) {
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
        final isMobile = ResponsiveUtils.isMobile(context);
        final isTablet = ResponsiveUtils.isTablet(context);
        
        // Responsive card width
        final maxCrossAxisExtent = isMobile ? 160.0 : (isTablet ? 170.0 : 180.0);
        
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxCrossAxisExtent,
            crossAxisSpacing: isMobile ? 8 : 12,
            mainAxisSpacing: isMobile ? 8 : 12,
            childAspectRatio: isMobile ? 0.85 : 0.9,
          ),
          padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
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
    final isOnline = user.status == 'Active'; // Simplified online status

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: isGrid
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
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
                              fontSize: 15,
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
                            width: 10,
                            height: 10,
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
                  const SizedBox(height: 8),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
    );
  }


  // Placeholder tabs
  Widget _buildOverviewTab(BuildContext context, Team team) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        final usersById = {for (final user in provider.allUsers) user.id: user};
        final members = team.memberIds
            .map((id) => usersById[id])
            .whereType<UserModel>()
            .toList();
        
        final teamMemberIds = members.map((m) => m.id).toSet();
        final teamTasks = provider.tasks.where((task) => 
          teamMemberIds.contains(task.assignedTo) || 
          task.assignedToUsers.any((id) => teamMemberIds.contains(id))
        ).toList();
        
        final tasksInProgress = teamTasks.where((t) => t.status == TaskStatus.inProgress).length;
        final tasksCompleted = teamTasks.where((t) => t.status == TaskStatus.completed).length;
        final tasksThisWeek = teamTasks.where((task) {
          final now = DateTime.now();
          final weekAgo = now.subtract(const Duration(days: 7));
          return task.createdAt != null && task.createdAt!.isAfter(weekAgo);
        }).length;
        
        final today = DateTime.now();
        final startOfToday = DateTime(today.year, today.month, today.day);
        final tasksCompletedToday = teamTasks.where((task) {
          if (task.updatedAt == null) return false;
          return task.status == TaskStatus.completed &&
              task.updatedAt!.isAfter(startOfToday);
        }).length;
        
        final activeProjects = provider.teams.length;
        final completionRate = teamTasks.isNotEmpty 
            ? ((tasksCompleted / teamTasks.length) * 100).toInt() 
            : 0;
        
        return FutureBuilder<List<TimesheetEntry>>(
          future: _loadTeamTimesheetEntries(team.id),
          builder: (context, timesheetSnapshot) {
            final timesheetEntries = timesheetSnapshot.data ?? [];
            
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = ResponsiveUtils.isMobile(context);
        final isTablet = ResponsiveUtils.isTablet(context);
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? AppSpacing.md : (isTablet ? AppSpacing.lg : AppSpacing.xl)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewHeader(context, team, provider),
              SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),
              _buildQuickStats(
                members.length, 
                activeProjects, 
                tasksThisWeek, 
                completionRate,
              ),
              SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),
              _buildTeamDescription(team, provider),
              SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),
              isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCurrentWorkSummary(tasksInProgress, tasksCompletedToday),
                        SizedBox(height: AppSpacing.lg),
                        _buildRecentActivity(teamTasks, provider),
                        SizedBox(height: AppSpacing.lg),
                        _buildTeamMembersList(members, teamTasks, timesheetEntries),
                        SizedBox(height: AppSpacing.lg),
                        _buildTeamHealthSummary(teamTasks, timesheetEntries, members),
                        SizedBox(height: AppSpacing.lg),
                        _buildQuickNavigation(context),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: isTablet ? 3 : 2,
                          child: Column(
                            children: [
                              _buildCurrentWorkSummary(tasksInProgress, tasksCompletedToday),
                              SizedBox(height: AppSpacing.xl),
                              _buildRecentActivity(teamTasks, provider),
                              SizedBox(height: AppSpacing.xl),
                              _buildTeamMembersList(members, teamTasks, timesheetEntries),
                            ],
                          ),
                        ),
                        SizedBox(width: isTablet ? AppSpacing.md : AppSpacing.xl),
                        Expanded(
                          flex: isTablet ? 2 : 1,
                          child: Column(
                            children: [
                              _buildTeamHealthSummary(teamTasks, timesheetEntries, members),
                              SizedBox(height: AppSpacing.xl),
                              _buildQuickNavigation(context),
                            ],
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        );
      },
    );
          },
        );
      },
    );
  }

  Future<List<TimesheetEntry>> _loadTeamTimesheetEntries(String teamId) async {
    try {
      final firebaseService = FirebaseService();
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      return await firebaseService.fetchTimesheetEntries(
        teamId: teamId,
        startDate: weekAgo,
        endDate: DateTime.now(),
      );
    } catch (e) {
      return [];
    }
  }

  Widget _buildOverviewHeader(BuildContext context, Team team, DashboardProvider provider) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              team.name.isNotEmpty ? team.name[0].toUpperCase() : 'T',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                team.name,
                      style: const TextStyle(
                  fontSize: 24,
                        fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
              const SizedBox(height: 4),
              Text(
                'Team workspace',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: () => _showEditDialog(context, provider, team),
          tooltip: 'Edit team',
        ),
        const SizedBox(width: AppSpacing.xs),
        AppButton(
          onPressed: () => _showMembersDialog(context, provider, team),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_add, size: 16),
              SizedBox(width: 4),
              Text('Add member'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(int members, int projects, int tasks, int completionRate) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = ResponsiveUtils.isMobile(context);
        
        if (isMobile) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.people_outline,
                      value: members.toString(),
                      label: 'Members',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.folder_outlined,
                      value: projects.toString(),
                      label: 'Active projects',
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.task_outlined,
                      value: tasks.toString(),
                      label: 'Tasks this week',
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.check_circle_outline,
                      value: '$completionRate%',
                      label: 'Completion rate',
                      color: const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.people_outline,
                  value: members.toString(),
                  label: 'Members',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.folder_outlined,
                  value: projects.toString(),
                  label: 'Active projects',
                  color: const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.task_outlined,
                  value: tasks.toString(),
                  label: 'Tasks this week',
                  color: const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.check_circle_outline,
                  value: '$completionRate%',
                  label: 'Completion rate',
                  color: const Color(0xFF059669),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return AppCard(
      borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamDescription(Team team, DashboardProvider provider) {
    return AppCard(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Team Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
                  team.description.isEmpty
                ? 'Add team description, information, and wiki'
                      : team.description,
                  style: TextStyle(
              fontSize: 14,
                    color: team.description.isEmpty
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWorkSummary(int inProgress, int completedToday) {
    return AppCard(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Work Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
          Text(
                      inProgress.toString(),
            style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tasks in progress',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      completedToday.toString(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tasks completed today',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
                ),
                const SizedBox(height: AppSpacing.md),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                Icons.bar_chart_outlined,
                size: 32,
                color: AppColors.textMuted.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(List<TaskModel> teamTasks, DashboardProvider provider) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadRecentAuditLogs(teamTasks),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppCard(
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final activities = snapshot.data ?? [];
        
        if (activities.isEmpty) {
          return AppCard(
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Text(
                    'No recent activity',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
            ),
          ),
        ],
      ),
    );
  }

        return AppCard(
          borderRadius: BorderRadius.circular(16),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...activities.asMap().entries.map((entry) {
                final index = entry.key;
                final activity = entry.value;
                final userName = activity['actionByName'] as String? ?? 'Unknown';
                final description = activity['description'] as String? ?? 'Activity';
                final timestamp = activity['timestamp'];
                DateTime? activityTime;
                if (timestamp != null) {
                  if (timestamp is DateTime) {
                    activityTime = timestamp;
                  } else if (timestamp is Timestamp) {
                    activityTime = timestamp.toDate();
                  }
                }
                final timeAgo = activityTime != null 
                    ? _formatTimeAgo(activityTime)
                    : 'Recently';
                
                return Column(
                  children: [
                    if (index > 0) const Divider(height: 32),
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
                                '$userName $description',
          style: const TextStyle(
            fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                timeAgo,
                                style: TextStyle(
                                  fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadRecentAuditLogs(List<TaskModel> teamTasks) async {
    try {
      final firebaseService = FirebaseService();
      final allLogs = <Map<String, dynamic>>[];
      
      for (final task in teamTasks.take(10)) {
        try {
          final logs = await firebaseService.getAuditLogs(task.id);
          allLogs.addAll(logs);
        } catch (e) {
          continue;
        }
      }
      
      allLogs.sort((a, b) {
        final aTime = a['timestamp'];
        final bTime = b['timestamp'];
        DateTime? aDate, bDate;
        
        if (aTime is DateTime) aDate = aTime;
        else if (aTime is Timestamp) aDate = aTime.toDate();
        
        if (bTime is DateTime) bDate = bTime;
        else if (bTime is Timestamp) bDate = bTime.toDate();
        
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });
      
      return allLogs.take(5).toList();
    } catch (e) {
      return [];
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  Widget _buildTeamMembersList(List<UserModel> members, List<TaskModel> tasks, List<TimesheetEntry> timesheetEntries) {
    return AppCard(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Team Members',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...members.map((member) {
            final memberTasks = tasks.where((t) => 
              t.assignedTo == member.id || t.assignedToUsers.contains(member.id)
            ).toList();
            final tasksThisWeek = memberTasks.where((task) {
              final now = DateTime.now();
              final weekAgo = now.subtract(const Duration(days: 7));
              return task.createdAt != null && task.createdAt!.isAfter(weekAgo);
            }).length;
            
            final memberHours = timesheetEntries
                .where((e) => e.userId == member.id)
                .fold<double>(0.0, (sum, entry) => sum + entry.hours);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        member.name.isNotEmpty ? member.name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
        Text(
                          member.name,
          style: const TextStyle(
            fontSize: 14,
                            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
                        const SizedBox(height: 2),
                        ShadBadge(
                          child: Text(
                            member.role,
                            style: const TextStyle(fontSize: 11),
          ),
        ),
      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$tasksThisWeek tasks',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${memberHours.toStringAsFixed(1)}h logged',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTeamHealthSummary(List<TaskModel> tasks, List<TimesheetEntry> timesheetEntries, List<UserModel> members) {
    final overdueTasks = tasks.where((t) => 
      t.dueDate.isBefore(DateTime.now()) && t.status != TaskStatus.completed
    ).length;
    
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekTimesheetEntries = timesheetEntries.where((e) => 
      e.date.isAfter(weekAgo)
    ).toList();
    
    final totalHours = weekTimesheetEntries.fold<double>(0.0, (sum, e) => sum + e.hours);
    final expectedHours = members.length * 40.0;
    final overtimeHours = totalHours > expectedHours ? totalHours - expectedHours : 0.0;
    
    final taskDistribution = <String, int>{};
    for (final task in tasks) {
      final assignee = task.assignedTo;
      if (assignee.isNotEmpty) {
        taskDistribution[assignee] = (taskDistribution[assignee] ?? 0) + 1;
      }
    }
    
    final maxTasks = taskDistribution.values.isNotEmpty ? taskDistribution.values.reduce((a, b) => a > b ? a : b) : 0;
    final minTasks = taskDistribution.values.isNotEmpty ? taskDistribution.values.reduce((a, b) => a < b ? a : b) : 0;
    final workloadStatus = maxTasks == 0 
        ? 'No tasks'
        : (maxTasks - minTasks) <= 2 
            ? 'Balanced'
            : 'Unbalanced';
    
    return AppCard(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Team Health Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildHealthBox('Overdue tasks', overdueTasks.toString(), Icons.warning_outlined, AppColors.danger),
          const SizedBox(height: AppSpacing.md),
          _buildHealthBox('Overtime hours', '${overtimeHours.toStringAsFixed(1)}h', Icons.access_time, AppColors.warning),
          const SizedBox(height: AppSpacing.md),
          _buildHealthBox('Workload distribution', workloadStatus, Icons.pie_chart_outline, 
            workloadStatus == 'Balanced' ? AppColors.success : AppColors.warning),
        ],
      ),
    );
  }

  Widget _buildHealthBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickNavigation(BuildContext context) {
    return AppCard(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Navigation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildNavCard(
            context,
            'View Tasks',
            Icons.task_outlined,
            () => setState(() => _activeTab = TeamTab.team),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildNavCard(
            context,
            'Workload',
            Icons.grid_view,
            () => setState(() => _activeTab = TeamTab.workload),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildNavCard(
            context,
            'Timesheet',
            Icons.access_time,
            () => setState(() => _activeTab = TeamTab.timesheet),
          ),
        ],
      ),
    );
  }

  Widget _buildNavCard(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
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
        
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = ResponsiveUtils.isMobile(context);
            final isTablet = ResponsiveUtils.isTablet(context);
            
            if (isMobile) {
              // Mobile: Stack vertically
              return Column(
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
                  // Bottom task sidebar (collapsible) - no fixed width on mobile
                  SizedBox(
                    height: 300,
                    child: _buildWorkloadTaskSidebar(context, teamTasks, isMobile: true),
                  ),
                ],
              );
            } else {
              // Desktop/Tablet: Side by side
              return Row(
                children: [
                  // Main workload area
                  Expanded(
                    flex: isTablet ? 2 : 3,
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
                  SizedBox(
                    width: isTablet ? 280 : 320,
                    child: _buildWorkloadTaskSidebar(context, teamTasks, isMobile: false),
                  ),
                ],
              );
            }
          },
        );
      },
    );
  }

  Widget _buildWorkloadControls(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    
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
          ? Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _buildWorkloadDropdown('Today', _workloadView, ['Today', '7 days', '14 days', '30 days'], (value) {
                  setState(() => _workloadView = value);
                }),
                _buildWorkloadDropdown('Time Estimates', _workloadTimeEstimate, ['Time Estimates', 'Hours', 'Days'], (value) {
                  setState(() => _workloadTimeEstimate = value);
                }),
                _buildWorkloadDropdown('14 days', _workloadView, ['7 days', '14 days', '30 days'], (value) {
                  setState(() => _workloadView = value);
                }),
                _buildWorkloadDropdown('Daily Scheduled', _workloadScheduleType, ['Daily Scheduled', 'Weekly', 'Monthly'], (value) {
                  setState(() => _workloadScheduleType = value);
                }),
                _buildWorkloadDropdown('Group: Assignee', _workloadGroupBy, ['Assignee', 'Project', 'Status'], (value) {
                  setState(() => _workloadGroupBy = value);
                }),
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
                IconButton(
                  icon: Icon(Icons.search, size: 20, color: _workloadShowSearch ? AppColors.primary : AppColors.textMuted),
                  onPressed: () {
                    setState(() => _workloadShowSearch = !_workloadShowSearch);
                  },
                  tooltip: 'Search',
                ),
                IconButton(
                  icon: const Icon(Icons.settings, size: 20),
                  onPressed: () => _showWorkloadSettingsDialog(context),
                  tooltip: 'Customize',
                ),
                IconButton(
                  icon: Icon(Icons.book, size: 20, color: _showBacklog ? AppColors.primary : AppColors.textMuted),
                  onPressed: () {
                    setState(() => _showBacklog = !_showBacklog);
                  },
                  tooltip: 'Backlog',
                ),
              ],
            )
          : Row(
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
        // Show only the selected value, or label if no value selected
        final displayText = selectedValue ?? label;
        return Text(
          displayText,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
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

  Widget _buildWorkloadTaskSidebar(BuildContext context, List<TaskModel> tasks, {bool isMobile = false}) {
    final unscheduledTasks = tasks.where((t) => t.status != TaskStatus.completed && t.dueDate.isAfter(DateTime.now().add(const Duration(days: 7)))).toList();
    final overdueTasks = tasks.where((t) => t.dueDate.isBefore(DateTime.now()) && t.status != TaskStatus.completed).toList();
    final noEstimateTasks = tasks.where((t) => true).toList(); // Placeholder
    
    return Container(
      width: isMobile ? null : 300,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          left: isMobile ? BorderSide.none : BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
          top: isMobile ? BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ) : BorderSide.none,
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
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        Team? team;
        try {
          team = provider.teams.firstWhere((t) => t.id == widget.teamId);
        } catch (_) {
          team = null;
        }
        if (team == null) return const SizedBox.shrink();

        final usersById = {
          for (final user in provider.allUsers) user.id: user,
        };
        final members = team.memberIds
            .map((id) => usersById[id])
            .whereType<UserModel>()
            .toList();

        return Column(
          children: [
            // Header with date range and actions
            _buildTimesheetHeader(context, team, provider, members),
            // Timesheet table
            Expanded(
              child: _buildTimesheetTable(context, team, provider, members),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimesheetHeader(
    BuildContext context,
    Team team,
    DashboardProvider provider,
    List<UserModel> members,
  ) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.md : (isTablet ? AppSpacing.lg : AppSpacing.xl),
        vertical: isMobile ? AppSpacing.md : AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Date range picker with improved ShadCN styling
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showTimesheetDateRangePicker(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _formatDateRange(_timesheetStartDate, _timesheetEndDate),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Previous week button with ShadCN styling
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                final daysDiff = _timesheetEndDate.difference(_timesheetStartDate).inDays;
                setState(() {
                  _timesheetEndDate = _timesheetStartDate.subtract(const Duration(days: 1));
                  _timesheetStartDate = _timesheetEndDate.subtract(Duration(days: daysDiff));
                });
                _loadTimesheetEntries();
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.chevron_left,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // Next week button with ShadCN styling
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                final daysDiff = _timesheetEndDate.difference(_timesheetStartDate).inDays;
                setState(() {
                  _timesheetStartDate = _timesheetEndDate.add(const Duration(days: 1));
                  _timesheetEndDate = _timesheetStartDate.add(Duration(days: daysDiff));
                });
                _loadTimesheetEntries();
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimesheetTable(
    BuildContext context,
    Team team,
    DashboardProvider provider,
    List<UserModel> members,
  ) {
    if (_isLoadingTimesheet) {
      return const Center(child: CircularProgressIndicator());
    }

    final dates = _generateDateRange(_timesheetStartDate, _timesheetEndDate);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            _buildTimesheetHeaderRow(dates),
            // Member rows
            ...members.map((member) => _buildTimesheetMemberRow(
                  context,
                  member,
                  dates,
                  team,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTimesheetHeaderRow(List<DateTime> dates) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // People column
          Container(
            width: isMobile ? 150 : 200,
            padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: const Text(
              'People',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // Date columns
          ...dates.map((date) => Container(
                width: isMobile ? 90 : (isTablet ? 100 : 120),
                padding: EdgeInsets.all(isMobile ? AppSpacing.xs : AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _getDayName(date.weekday),
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${date.month}/${date.day}',
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              )),
          // Total column
          Container(
            width: isMobile ? 80 : 100,
            padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
            child: const Text(
              'Total',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimesheetMemberRow(
    BuildContext context,
    UserModel member,
    List<DateTime> dates,
    Team team,
  ) {
    // Filter entries for this member within the visible date range only
    final visibleDateSet = dates.map((d) => '${d.year}-${d.month}-${d.day}').toSet();
    final memberEntries = _timesheetEntries.where((e) {
      if (e.userId != member.id) return false;
      final entryDateKey = '${e.date.year}-${e.date.month}-${e.date.day}';
      return visibleDateSet.contains(entryDateKey);
    }).toList();

    final totalHours = memberEntries.fold<double>(
      0.0,
      (sum, entry) => sum + entry.hours,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5), width: 1),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = ResponsiveUtils.isMobile(context);
          
          return Row(
            children: [
              // Member info column
              Container(
                width: isMobile ? 150 : 200,
                padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: isMobile ? 24 : 32,
                          height: isMobile ? 24 : 32,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              member.name.isNotEmpty
                                  ? member.name[0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: isMobile ? 12 : 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isMobile ? AppSpacing.xs : AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.name,
                                style: TextStyle(
                                  fontSize: isMobile ? 12 : 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${totalHours.toStringAsFixed(1)}h',
                                style: TextStyle(
                                  fontSize: isMobile ? 10 : 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Date columns
              ...dates.map((date) => _buildTimesheetCell(
                    context,
                    member,
                    date,
                    team,
                  )),
              // Total column
              Container(
                width: isMobile ? 80 : 100,
                padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
                child: Text(
                  '${totalHours.toStringAsFixed(1)}h',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimesheetCell(
    BuildContext context,
    UserModel member,
    DateTime date,
    Team team,
  ) {
    // Normalize date to start of day for consistent comparison
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    final entry = _timesheetEntries.firstWhere(
      (e) {
        // Normalize entry date for comparison
        final entryDate = DateTime(e.date.year, e.date.month, e.date.day);
        return e.userId == member.id &&
            entryDate.year == normalizedDate.year &&
            entryDate.month == normalizedDate.month &&
            entryDate.day == normalizedDate.day;
      },
      orElse: () => TimesheetEntry(
        id: '',
        userId: member.id,
        userName: member.name,
        teamId: team.id,
        date: normalizedDate,
        hours: 0.0,
      ),
    );

    final isEditing = _editingEntryId == entry.id ||
        (_editingUserId == member.id &&
            _editingDate != null &&
            _editingDate!.year == date.year &&
            _editingDate!.month == date.month &&
            _editingDate!.day == date.day);

    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    
    return InkWell(
      onTap: () => _showTimeEntryDialog(context, member, date, team, entry),
      child: Container(
        width: isMobile ? 90 : (isTablet ? 100 : 120),
        padding: EdgeInsets.all(isMobile ? AppSpacing.xs : AppSpacing.md),
        decoration: BoxDecoration(
          color: isEditing ? AppColors.primarySoft.withValues(alpha: 0.3) : AppColors.surface,
          border: Border(
            right: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Center(
          child: Text(
            entry.hours > 0 ? '${entry.hours.toStringAsFixed(1)}h' : '0h',
            style: TextStyle(
              color: entry.hours > 0 ? AppColors.textPrimary : AppColors.textMuted,
              fontWeight: entry.hours > 0 ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showTimeEntryDialog(
    BuildContext context,
    UserModel member,
    DateTime date,
    Team team,
    TimesheetEntry? existingEntry,
  ) async {
    final hoursController = TextEditingController(
      text: existingEntry?.hours.toStringAsFixed(2) ?? '0.00',
    );
    final descriptionController = TextEditingController(
      text: existingEntry?.description ?? '',
    );
    final taskTitleController = TextEditingController(
      text: existingEntry?.taskTitle ?? '',
    );
    BillableStatus? billableStatus = existingEntry?.billableStatus;
    final selectedTags = <String>[...?existingEntry?.tags];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return ShadDialog(
              title: Text('Log time for ${member.name}'),
              child: Material(
                color: Colors.transparent,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      // Hours input
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hours',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          ShadInput(
                            controller: hoursController,
                            placeholder: const Text('0.00'),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Task/Project input
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Task/Project',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          ShadInput(
                            controller: taskTitleController,
                            placeholder: const Text('Enter task or project name...'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Description input
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          ShadInput(
                            controller: descriptionController,
                            placeholder: const Text('Enter description...'),
                            maxLines: 3,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Billable Status dropdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Billable Status',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          AppSelect<BillableStatus>(
                            value: billableStatus,
                            options: BillableStatus.values.map((status) {
                              return SelectOption<BillableStatus>(
                                value: status,
                                label: status.name,
                              );
                            }).toList(),
                            selectedOptionBuilder: (context, value) {
                              return Text(value?.name ?? 'Select status...');
                            },
                            onChanged: (value) {
                              setState(() {
                                billableStatus = value;
                              });
                            },
                            placeholder: 'Select billable status...',
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
              actions: [
                AppButton(
                  label: 'Cancel',
                  variant: AppButtonVariant.outline,
                  onPressed: () => Navigator.pop(context),
                ),
                if (existingEntry != null && existingEntry.id.isNotEmpty)
                  AppButton(
                    label: 'Delete',
                    variant: AppButtonVariant.destructive,
                    onPressed: () {
                      Navigator.pop(context, {'action': 'delete'});
                    },
                  ),
                AppButton(
                  label: 'Save',
                  variant: AppButtonVariant.primary,
                  onPressed: () {
                    final hours = double.tryParse(hoursController.text) ?? 0.0;
                    Navigator.pop(context, {
                      'action': 'save',
                      'hours': hours,
                      'description': descriptionController.text,
                      'taskTitle': taskTitleController.text,
                      'billableStatus': billableStatus ?? BillableStatus.notSet,
                      'tags': selectedTags,
                    });
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      final firebaseService = FirebaseService();
      if (result['action'] == 'delete' && existingEntry != null && existingEntry.id.isNotEmpty) {
        await firebaseService.deleteTimesheetEntry(existingEntry.id);
        // Small delay to ensure Firebase has processed the delete
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          _loadTimesheetEntries();
        }
      } else if (result['action'] == 'save') {
        try {
          final hours = result['hours'] as double;
          // Normalize date to start of day (00:00:00) to ensure consistent comparison
          final normalizedDate = DateTime(date.year, date.month, date.day);
          
          if (hours > 0) {
            // Check if an entry already exists for this user/date/team combination
            final existingEntryInDb = await firebaseService.getTimesheetEntryByDate(
              userId: member.id,
              teamId: team.id,
              date: normalizedDate,
            );

            final entry = TimesheetEntry(
              id: existingEntryInDb?.id ?? existingEntry?.id ?? '',
              userId: member.id,
              userName: member.name,
              teamId: team.id,
              date: normalizedDate,
              hours: hours,
              taskId: result['taskId'] as String?,
              taskTitle: result['taskTitle'] as String?,
              description: result['description'] as String?,
              billableStatus: result['billableStatus'] as BillableStatus,
              tags: (result['tags'] as List<dynamic>?)?.cast<String>() ?? [],
            );

            if (existingEntryInDb != null && existingEntryInDb.id.isNotEmpty) {
              // Update existing entry
              await firebaseService.updateTimesheetEntry(entry);
            } else {
              // Create new entry
              await firebaseService.addTimesheetEntry(entry);
            }
            
            // Small delay to ensure Firebase has processed the write
            await Future.delayed(const Duration(milliseconds: 500));
            
            if (mounted) {
              await _loadTimesheetEntries();
            }
          } else {
            // If hours is 0, delete the entry if it exists
            if (existingEntry != null && existingEntry.id.isNotEmpty) {
              await firebaseService.deleteTimesheetEntry(existingEntry.id);
              await Future.delayed(const Duration(milliseconds: 500));
              if (mounted) {
                await _loadTimesheetEntries();
              }
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error saving timesheet entry: $e')),
            );
          }
        }
      }
    }
  }

  List<DateTime> _generateDateRange(DateTime start, DateTime end) {
    final dates = <DateTime>[];
    var current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    while (!current.isAfter(endDate)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[start.month - 1]} ${start.day} - ${months[end.month - 1]} ${end.day}';
  }

  Future<void> _showTimesheetDateRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: _timesheetStartDate,
        end: _timesheetEndDate,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
              secondary: AppColors.primarySoft,
              onSecondary: AppColors.primary,
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
              elevation: 8,
            ),
            textTheme: Theme.of(context).textTheme.copyWith(
              bodyLarge: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              bodyMedium: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
              titleMedium: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _timesheetStartDate = picked.start;
        _timesheetEndDate = picked.end;
      });
      _loadTimesheetEntries();
    }
  }

  Future<void> _loadTimesheetEntries() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingTimesheet = true;
    });

    try {
      final firebaseService = FirebaseService();
      // Normalize dates to start/end of day for proper range query
      final startDate = DateTime(_timesheetStartDate.year, _timesheetStartDate.month, _timesheetStartDate.day);
      final endDate = DateTime(_timesheetEndDate.year, _timesheetEndDate.month, _timesheetEndDate.day, 23, 59, 59);
      
      final entries = await firebaseService.fetchTimesheetEntries(
        teamId: widget.teamId,
        startDate: startDate,
        endDate: endDate,
      );
      
      // Deduplicate entries: if multiple entries exist for same user/date, keep the most recent one
      final deduplicatedEntries = <String, TimesheetEntry>{};
      for (final entry in entries) {
        final key = '${entry.userId}_${entry.date.year}_${entry.date.month}_${entry.date.day}';
        if (!deduplicatedEntries.containsKey(key)) {
          deduplicatedEntries[key] = entry;
        } else {
          // Keep the entry with the most recent updatedAt or createdAt
          final existing = deduplicatedEntries[key]!;
          final existingTime = existing.updatedAt ?? existing.createdAt ?? DateTime(1970);
          final newTime = entry.updatedAt ?? entry.createdAt ?? DateTime(1970);
          if (newTime.isAfter(existingTime)) {
            deduplicatedEntries[key] = entry;
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _timesheetEntries = deduplicatedEntries.values.toList();
          _isLoadingTimesheet = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTimesheet = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading timesheet: $e')),
        );
      }
    }
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

    // Sort
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'Name':
          return a.name.compareTo(b.name);
        case 'Role':
          return a.role.compareTo(b.role);
        case 'Status':
          return a.status.compareTo(b.status);
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
      builder: (context) => ShadDialog(
        title: const Text('Delete team'),
        child: Text(
          'Are you sure you want to delete ${team.name}?',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          AppButton(
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          AppButton(
            variant: AppButtonVariant.destructive,
            onPressed: () => Navigator.of(context).pop(true),
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
                  status: 'Active',
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
