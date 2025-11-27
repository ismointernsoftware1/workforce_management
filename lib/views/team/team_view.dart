import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/shadcn/shadcn.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/user_model.dart';
import '../../models/team_model.dart';
import '../widgets/add_user_dialog.dart';
import '../widgets/add_team_dialog.dart';
import '../widgets/team_members_dialog.dart';
import 'team_detail_page.dart';

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
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Padding(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'People',
                style: TextStyle(
                  fontSize: isMobile ? 28 : 36,
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
                  fontSize: isMobile ? 14 : 16,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShadTooltip(
                message: 'Refresh',
                child: ShadButton(
                  onPressed: () {
                    if (_tabController.index == 0) {
                      provider.refreshUsers();
                    } else {
                      provider.refreshTeams();
                    }
                  },
                  icon: const Icon(Icons.refresh, color: AppColors.textMuted),
                  variant: ShadButtonVariant.ghost,
                  size: ShadButtonSize.icon,
                  child: const SizedBox.shrink(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ShadTooltip(
                message: _tabController.index == 0
                    ? 'Add User'
                    : 'Create Team',
                child: ShadButton(
                  onPressed: () {
                    if (_tabController.index == 0) {
                      _showAddUserDialog(context, provider);
                    } else {
                      _showAddTeamDialog(context, provider);
                    }
                  },
                  icon: const Icon(Icons.add, color: AppColors.textMuted),
                  variant: ShadButtonVariant.ghost,
                  size: ShadButtonSize.icon,
                  child: const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people, size: 18),
                if (!isMobile) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const Text('All People'),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.groups, size: 18),
                if (!isMobile) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const Text('All Teams'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllPeopleView(BuildContext context, DashboardProvider provider) {
    final filteredUsers = _filteredUsers(provider.users);
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (provider.isLoading && filteredUsers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'People Directory',
                      style: TextStyle(
                        fontSize: isMobile ? 22 : 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage and view all users',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: isMobile ? 12 : 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                ShadButton(
                  onPressed: () => _showAddUserDialog(context, provider),
                  variant: ShadButtonVariant.default_,
                  size: ShadButtonSize.md,
                  icon: const Icon(Icons.add, size: 20),
                  child: const Text('Add User'),
                )
              else
                ShadButton(
                  onPressed: () => _showAddUserDialog(context, provider),
                  variant: ShadButtonVariant.default_,
                  size: ShadButtonSize.sm,
                  icon: const Icon(Icons.add, size: 18),
                  child: const SizedBox.shrink(),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (isMobile) ...[
            ShadInput(
              controller: _searchController,
              hintText: 'Search by name or email...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              onChanged: (_) => setState(() {}),
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
                    onChanged: (_) => setState(() {}),
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
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.people_alt_outlined,
                      size: 64,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'No employees yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Add your first user to get started.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ShadButton(
                      onPressed: () => _showAddUserDialog(context, provider),
                      variant: ShadButtonVariant.default_,
                      size: ShadButtonSize.md,
                      icon: const Icon(Icons.add, size: 20),
                      child: const Text('Add User'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Container(
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
                    ? const Center(
                        child: Text(
                          'No employees match the current filters.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : isMobile
                        ? ListView.builder(
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              return _buildMobileUserCard(user, provider);
                            },
                          )
                        : ListView.builder(
                            itemCount: filteredUsers.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return _buildTableHeader();
                              }
                              final user = filteredUsers[index - 1];
                              return _buildTableRow(user, provider);
                            },
                          ),
              ),
            ),
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
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Padding(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Teams',
                style: TextStyle(
                  fontSize: isMobile ? 22 : 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ShadButton(
                onPressed: () => _showAddTeamDialog(context, provider),
                variant: ShadButtonVariant.default_,
                size: isMobile ? ShadButtonSize.sm : ShadButtonSize.md,
                icon: const Icon(Icons.group_add, size: 20),
                child: isMobile
                    ? const SizedBox.shrink()
                    : const Text('Create Team'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          ShadInput(
            controller: _teamSearchController,
            hintText: 'Search teams...',
            prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: provider.teams.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.groups_outlined,
                          size: 64,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'No teams yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'Create a team to collaborate with your members.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ShadButton(
                          onPressed: () => _showAddTeamDialog(context, provider),
                          variant: ShadButtonVariant.default_,
                          child: const Text('Create Team'),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 1 : (MediaQuery.of(context).size.width < 1200 ? 2 : 4),
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: isMobile ? 1.2 : 0.95,
                    ),
                    itemCount: filteredTeams.length,
                    itemBuilder: (context, index) {
                      final team = filteredTeams[index];
                      final members = team.memberIds
                          .map((id) => usersById[id])
                          .whereType<UserModel>()
                          .toList();
                      return InkWell(
                        onTap: () => _openTeamDetail(context, team),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      team.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                    ShadTooltip(
                                      message: 'Edit',
                                      child: ShadButton(
                                        onPressed: () =>
                                            _showEditTeamDialog(
                                                context, provider, team),
                                        icon: const Icon(Icons.edit, size: 18),
                                        variant: ShadButtonVariant.ghost,
                                        size: ShadButtonSize.icon,
                                        child: const SizedBox.shrink(),
                                      ),
                                    ),
                                    ShadTooltip(
                                      message: 'Delete',
                                      child: ShadButton(
                                        onPressed: () =>
                                            _confirmDeleteTeam(
                                                context, provider, team),
                                        icon: const Icon(Icons.delete_outline,
                                            size: 18, color: AppColors.danger),
                                        variant: ShadButtonVariant.ghost,
                                        size: ShadButtonSize.icon,
                                        child: const SizedBox.shrink(),
                                      ),
                                    ),
                                    ],
                                  ),
                                ],
                              ),
                              Text(
                                '${team.memberIds.length} members',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                              if (team.description.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  team.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AppColors.textMuted),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.md),
                              Expanded(
                                child: members.isEmpty
                                    ? Align(
                                        alignment: Alignment.centerLeft,
                                        child: ShadBadge(
                                          label: 'No members yet',
                                          variant: ShadBadgeVariant.secondary,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              Align(
                                alignment: Alignment.bottomRight,
                                child:                                 ShadButton(
                                  onPressed: () => _showTeamMembersDialog(
                                      context, provider, team),
                                  variant: ShadButtonVariant.ghost,
                                  size: ShadButtonSize.sm,
                                  icon: const Icon(Icons.person_add_alt_1,
                                      size: 16),
                                  child: const Text('Add members'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<UserModel> _filteredUsers(List<UserModel> users) {
    final query = _searchController.text.toLowerCase();
    return users.where((user) {
      final matchesQuery = query.isEmpty ||
          user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
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
      margin: const EdgeInsets.all(AppSpacing.sm),
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

  Widget _buildTableRow(UserModel user, DashboardProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth < 1200 && constraints.maxWidth >= 768;
          return Row(
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
                          Text(
                            user.email,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
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
              if (!isTablet) ...[
                Expanded(
                  flex: 2,
                  child: Text(
                    user.role,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    user.email,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
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
          );
        },
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
        onSave: (newUser) {
          if (user == null) {
            return provider.addUser(newUser);
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

  void _openTeamDetail(BuildContext context, Team team) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeamDetailPage(teamId: team.id),
      ),
    );
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
