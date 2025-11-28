import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/shadcn/shadcn.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/user_model.dart';
import '../../models/team_model.dart';
import '../../utils/responsive_utils.dart';
import '../widgets/add_user_dialog.dart';
import '../widgets/add_team_dialog.dart';
import '../widgets/team_members_dialog.dart';

class TeamView extends StatefulWidget {
  const TeamView({super.key});

  @override
  State<TeamView> createState() => _TeamViewState();
}

class _TeamViewState extends State<TeamView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _teamSearchController = TextEditingController();
  String _statusFilter = 'All';
  final Set<String> _expandedTeamIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _teamSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    return Column(
      children: [
        _buildHeader(context, provider),
        _buildTabs(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAllPeopleView(context, provider),
              _buildAllTeamsView(context, provider),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, DashboardProvider provider) {
    return Padding(
      padding: ResponsiveUtils.getPadding(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
            'People',
            style: TextStyle(
                    fontSize: ResponsiveUtils.getFontSize(
                      context,
                      mobile: 28,
                      tablet: 32,
                      desktop: 36,
                    ),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
                    letterSpacing: -0.8,
                    height: 1.1,
            ),
          ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Manage your team members and groups',
                  style: TextStyle(
                color: AppColors.textMuted,
                    fontSize: ResponsiveUtils.getFontSize(
                      context,
                      mobile: 14,
                      tablet: 15,
                      desktop: 16,
                    ),
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
              ),
            ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final isMobile = ResponsiveUtils.isMobile(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      child: Container(
      decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
            child: Row(
              children: [
            Expanded(
              child: _buildTabButton(
                index: 0,
                icon: Icons.people,
                label: 'All People',
                isMobile: isMobile,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildTabButton(
                index: 1,
                icon: Icons.groups,
                label: 'All Teams',
                isMobile: isMobile,
              ),
            ),
              ],
            ),
          ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String label,
    required bool isMobile,
  }) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? AppSpacing.sm : AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            if (!isMobile) ...[
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAllPeopleView(BuildContext context, DashboardProvider provider) {
    final filteredUsers = _filteredUsers(provider.users);
    final isMobile = ResponsiveUtils.isMobile(context);

    if (provider.isLoading && filteredUsers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: ResponsiveUtils.getPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    'People Directory',
                    style: TextStyle(
                          fontSize: ResponsiveUtils.getFontSize(
                            context,
                            mobile: 22,
                            tablet: 24,
                            desktop: 28,
                          ),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                      const SizedBox(height: 4),
                  Text(
                    'Manage and view all users',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: ResponsiveUtils.getFontSize(
                            context,
                            mobile: 12,
                            tablet: 13,
                            desktop: 14,
                          ),
                        ),
                  ),
                ],
              ),
                ),
                if (!isMobile)
                  ShadButton(
                    onPressed: () => _showAddUserDialog(context, provider),
                    variant: ShadButtonVariant.outline,
                    size: ShadButtonSize.md,
                    icon: const Icon(Icons.add, size: 20),
                    child: const Text('Add User'),
                  )
                else
                  ShadButton(
                    onPressed: () => _showAddUserDialog(context, provider),
                    variant: ShadButtonVariant.outline,
                    size: ShadButtonSize.sm,
                    icon: const Icon(Icons.add, size: 18),
                    child: const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (isMobile) ...[
            ShadInput(
              controller: _searchController,
              hintText: 'Search by name or email...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              onChanged: (query) {
                setState(() {});
              },
          ),
            const SizedBox(height: AppSpacing.md),
            ShadSelect<String>(
              value: _statusFilter,
              hint: 'All Status',
              items: [
                const ShadSelectItem(value: 'All', label: 'All Status'),
                const ShadSelectItem(value: 'Active', label: 'Active'),
                const ShadSelectItem(value: 'On leave', label: 'On leave'),
                const ShadSelectItem(value: 'Inactive', label: 'Inactive'),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _statusFilter = value);
                }
              },
            ),
          ] else ...[
          Row(
            children: [
              Expanded(
                  child: ShadInput(
                  controller: _searchController,
                    hintText: 'Search by name or email...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                    onChanged: (query) {
                      setState(() {});
                    },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 160,
                  child: ShadSelect<String>(
                  value: _statusFilter,
                    hint: 'All Status',
                    items: [
                      const ShadSelectItem(value: 'All', label: 'All Status'),
                      const ShadSelectItem(value: 'Active', label: 'Active'),
                      const ShadSelectItem(value: 'On leave', label: 'On leave'),
                      const ShadSelectItem(value: 'Inactive', label: 'Inactive'),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _statusFilter = value);
                    }
                  },
                ),
              ),
            ],
          ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (provider.users.isEmpty && !provider.isLoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl * 2),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                      Icons.people_alt_outlined,
                      size: 64,
                        color: AppColors.primary,
                    ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const Text(
                      'No employees yet',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Add your first user to get started.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 16,
                    ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ShadButton(
                      onPressed: () => _showAddUserDialog(context, provider),
                      variant: ShadButtonVariant.outline,
                      size: ShadButtonSize.md,
                      icon: const Icon(Icons.add, size: 20),
                      child: const Text('Add User'),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
                ),
                child: filteredUsers.isEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl * 2),
                      child: const Center(
                        child: Text(
                          'No employees match the current filters.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 16,
                          ),
                        ),
                        ),
                      )
                  : isMobile
                      ? Column(
                          children: filteredUsers.map((user) {
                            return _buildMobileUserCard(user, provider);
                          }).toList(),
                        )
                      : Column(
                          children: [
                            _buildTableHeader(),
                            ...filteredUsers.asMap().entries.map((entry) {
                              final index = entry.key;
                              final user = entry.value;
                              final isLast = index == filteredUsers.length - 1;
                              return _buildTableRow(user, provider, isLast: isLast);
                            }).toList(),
                          ],
                      ),
              ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildAllTeamsView(
      BuildContext context, DashboardProvider provider) {
    final filteredTeams = _filteredTeams(provider.teams);
    final usersById = {
      for (final user in provider.allUsers) user.id: user,
    };
    final isMobile = ResponsiveUtils.isMobile(context);

    return SingleChildScrollView(
      padding: ResponsiveUtils.getPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                'All Teams',
                style: TextStyle(
                        fontSize: isMobile ? 22 : 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage members and team settings',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: isMobile ? 12 : 14,
                      ),
                    ),
                  ],
                ),
              ),
              ShadButton(
                onPressed: () => _showAddTeamDialog(context, provider),
                variant: ShadButtonVariant.outline,
                size: isMobile ? ShadButtonSize.sm : ShadButtonSize.md,
                icon: const Icon(Icons.group_add, size: 20),
                child:
                    isMobile ? const SizedBox.shrink() : const Text('Create Team'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          ShadInput(
            controller: _teamSearchController,
              hintText: 'Search teams...',
            prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
            onChanged: (query) {
              setState(() {});
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          if (filteredTeams.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl * 2),
              child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                          Icons.groups_outlined,
                          size: 64,
                        color: AppColors.primary,
                        ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                        const Text(
                          'No teams yet',
                          style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'Create a team to collaborate with your members.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 16,
                        ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ShadButton(
                      onPressed: () => _showAddTeamDialog(context, provider),
                      variant: ShadButtonVariant.outline,
                      size: ShadButtonSize.md,
                      icon: const Icon(Icons.group_add, size: 20),
                      child: const Text('Create Team'),
                    ),
                      ],
                    ),
              ),
            )
          else
            Column(
              children: filteredTeams.map((team) {
                      final members = team.memberIds
                          .map((id) => usersById[id])
                          .whereType<UserModel>()
                          .toList();
                final isExpanded = _expandedTeamIds.contains(team.id);

                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textPrimary.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    team.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: ResponsiveUtils.getFontSize(
                                        context,
                                        mobile: 20,
                                        tablet: 22,
                                        desktop: 24,
                                      ),
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        size: 16,
                                        color: AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${team.memberIds.length} members',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (team.description.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      team.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ShadButton(
                                  onPressed: () => _showTeamMembersDialog(
                                      context, provider, team),
                                  variant: ShadButtonVariant.outline,
                                  size: ShadButtonSize.sm,
                                  icon: const Icon(Icons.person_add_alt_1, size: 16),
                                  child: const Text('Add members'),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                ShadTooltip(
                                  message: isExpanded ? 'Hide members' : 'Show members',
                                  child: ShadButton(
                                    onPressed: () {
                                      setState(() {
                                        if (isExpanded) {
                                          _expandedTeamIds.remove(team.id);
                                        } else {
                                          _expandedTeamIds.add(team.id);
                                        }
                                      });
                                    },
                                    variant: ShadButtonVariant.ghost,
                                    size: ShadButtonSize.icon,
                                    icon: Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      size: 20,
                                      color: AppColors.textMuted,
                                    ),
                                    child: const SizedBox.shrink(),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                ShadTooltip(
                                  message: 'Edit',
                                  child: ShadButton(
                                    onPressed: () =>
                                        _showEditTeamDialog(context, provider, team),
                                    variant: ShadButtonVariant.ghost,
                                    size: ShadButtonSize.icon,
                                    icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textMuted),
                                    child: const SizedBox.shrink(),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                ShadTooltip(
                                  message: 'Delete',
                                  child: ShadButton(
                                    onPressed: () =>
                                        _confirmDeleteTeam(context, provider, team),
                                    variant: ShadButtonVariant.ghost,
                                    size: ShadButtonSize.icon,
                                    icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                                    child: const SizedBox.shrink(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isExpanded) ...[
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.border.withValues(alpha: 0.3),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Team Members',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              members.isEmpty
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.lg,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceAlt,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.border.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            size: 20,
                                            color: AppColors.textMuted,
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Text(
                                            'No members yet',
                                            style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Column(
                                      children: members
                                          .map(
                                            (member) => Container(
                                              margin: const EdgeInsets.only(
                                                  bottom: AppSpacing.sm),
                                              padding: const EdgeInsets.all(
                                                  AppSpacing.md),
                                              decoration: BoxDecoration(
                                                color: AppColors.surfaceAlt,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: AppColors.border.withValues(alpha: 0.2),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primarySoft,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: AppColors.primary.withValues(alpha: 0.2),
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        member.name.isNotEmpty
                                                            ? member.name[0]
                                                                .toUpperCase()
                                                            : '?',
                                                        style: TextStyle(
                                                          color: AppColors.primary,
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: AppSpacing.md),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          member.name,
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 15,
                                                            color: AppColors.textPrimary,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          member.email,
                                                          style: TextStyle(
                                                            color: AppColors.textMuted,
                                                            fontSize: 13,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                            ],
                          ),
                        ),
                      ],
                          ],
                        ),
                      );
              }).toList(),
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  List<UserModel> _filteredUsers(List<UserModel> users) {
    final query = _searchController.text.toLowerCase().trim();
    return users.where((user) {
      // Filter by search query
      final matchesQuery = query.isEmpty ||
          user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
      // Filter by status
      final matchesStatus =
          _statusFilter == 'All' || user.status == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();
  }

  List<Team> _filteredTeams(List<Team> teams) {
    final query = _teamSearchController.text.toLowerCase();
    if (query.isEmpty) return teams;
    return teams
        .where((team) => team.name.toLowerCase().contains(query))
        .toList();
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: const [
          Expanded(flex: 2, child: _HeaderCell('Name')),
          Expanded(flex: 2, child: _HeaderCell('Role')),
          Expanded(flex: 2, child: _HeaderCell('Email')),
          Expanded(child: _HeaderCell('Status')),
          SizedBox(width: 120, child: _HeaderCell('Actions')),
        ],
      ),
    );
  }

  Widget _buildMobileUserCard(UserModel user, DashboardProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 80,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _StatusChip(status: user.status),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Role',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.role,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 72,
                child: Wrap(
                  spacing: 2,
                  runSpacing: 4,
                  alignment: WrapAlignment.end,
                  children: [
                    ShadTooltip(
                      message: 'Edit',
                      child: ShadButton(
                        onPressed: () =>
                            _showAddUserDialog(context, provider, user: user),
                        icon: const Icon(Icons.edit, size: 18),
                        variant: ShadButtonVariant.ghost,
                        size: ShadButtonSize.icon,
                        child: const SizedBox.shrink(),
                      ),
                    ),
                    ShadTooltip(
                      message: 'Remove',
                      child: ShadButton(
                        onPressed: () => _confirmDelete(context, provider, user),
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: AppColors.danger),
                        variant: ShadButtonVariant.ghost,
                        size: ShadButtonSize.icon,
                        child: const SizedBox.shrink(),
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

  Widget _buildTableRow(UserModel user, DashboardProvider provider, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: isLast
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              )
            : null,
        border: Border(
          top: BorderSide(
            color: AppColors.border.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primarySoft,
                  child: Text(
                    user.name.isNotEmpty
                        ? user.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              user.role,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              user.email,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _StatusChip(status: user.status),
            ),
          ),
          SizedBox(
            width: 120,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: ShadTooltip(
                    message: 'Edit',
                    child: ShadButton(
                  onPressed: () =>
                      _showAddUserDialog(context, provider, user: user),
                  icon: const Icon(Icons.edit, size: 18),
                      variant: ShadButtonVariant.ghost,
                      size: ShadButtonSize.icon,
                      child: const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: ShadTooltip(
                    message: 'Remove',
                    child: ShadButton(
                  onPressed: () => _confirmDelete(context, provider, user),
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: AppColors.danger),
                      variant: ShadButtonVariant.ghost,
                      size: ShadButtonSize.icon,
                      child: const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(
    BuildContext context,
    DashboardProvider provider, {
    UserModel? user,
  }) {
    showDialog(
      context: context,
      builder: (context) => AddUserDialog(
        initialUser: user,
        onSave: (newUser, {String? password}) {
          if (user == null) {
            return provider.addUser(newUser, password: password);
          } else {
            return provider.updateUser(newUser);
          }
        },
      ),
    );
  }

  void _showAddTeamDialog(
    BuildContext context,
    DashboardProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AddTeamDialog(
        onSubmit: (team) => provider.addTeam(team),
      ),
    );
  }

  void _showEditTeamDialog(
    BuildContext context,
    DashboardProvider provider,
    Team team,
  ) {
    showDialog(
      context: context,
      builder: (context) => AddTeamDialog(
        initialTeam: team,
        onSubmit: (updated) => provider.updateTeam(updated),
      ),
    );
  }

  void _showTeamMembersDialog(
    BuildContext context,
    DashboardProvider provider,
    Team team,
  ) {
    showDialog(
      context: context,
      builder: (context) => TeamMembersDialog(
        team: team,
        users: provider.allUsers,
        onSave: (memberIds) =>
            provider.updateTeamMembers(team.id, memberIds),
      ),
    );
  }

  Future<void> _confirmDeleteTeam(
    BuildContext context,
    DashboardProvider provider,
    Team team,
  ) async {
    final confirm = await ShadDialog.show<bool>(
      context: context,
      title: 'Delete team',
        content: Text('Delete ${team.name}?'),
        actions: [
        ShadButton(
            onPressed: () => Navigator.of(context).pop(false),
          variant: ShadButtonVariant.outline,
            child: const Text('Cancel'),
          ),
        ShadButton(
            onPressed: () => Navigator.of(context).pop(true),
          variant: ShadButtonVariant.destructive,
            child: const Text('Delete'),
          ),
        ],
    );

    if (confirm == true) {
      await provider.deleteTeam(team.id);
    }
  }

  void _confirmDelete(
    BuildContext context,
    DashboardProvider provider,
    UserModel user,
  ) {
    ShadDialog.show(
      context: context,
      title: 'Remove employee',
        content: Text('Are you sure you want to remove ${user.name}?'),
        actions: [
        ShadButton(
            onPressed: () => Navigator.of(context).pop(),
          variant: ShadButtonVariant.outline,
            child: const Text('Cancel'),
          ),
        ShadButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await provider.deleteUser(user.id);
              if (context.mounted) {
              ShadToast.show(
                context,
                title: 'Success',
                description: '${user.name} removed',
                variant: ShadToastVariant.success,
                );
              }
            },
          variant: ShadButtonVariant.destructive,
            child: const Text('Remove'),
          ),
        ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontSize: 13,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  Color get _backgroundColor {
    switch (status) {
      case 'Active':
        return AppColors.success.withValues(alpha: 0.15);
      case 'On leave':
        return AppColors.warning.withValues(alpha: 0.15);
      default:
        return AppColors.border;
    }
  }

  Color get _textColor {
    switch (status) {
      case 'Active':
        return AppColors.success;
      case 'On leave':
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
