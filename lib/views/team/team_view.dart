import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/user_model.dart';
import '../../models/team_model.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/rbac_utils.dart';
import '../../widgets/shadcn/shadcn_widgets.dart';
import '../../widgets/permission_wrapper.dart';
import '../widgets/add_user_dialog.dart';
import '../widgets/add_team_dialog.dart';
import '../widgets/invite_user_dialog.dart';
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
  bool _isGridView = true; // Grid view by default (ClickUp style)
  String _createdFilter = 'All';
  String _sortBy = 'Default';

  Future<Map<String, bool>> _getTeamPermissions() async {
    return {
      'create': await RBACUtils.canCreate('team'),
      'update': await RBACUtils.canUpdate('team'),
      'delete': await RBACUtils.canDelete('team'),
    };
  }

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
    final isMobile = ResponsiveUtils.isMobile(context);
    
    if (isMobile) {
      // For mobile: full page scroll
      return Container(
        color: const Color(0xFFF5F6F8),
        child: SingleChildScrollView(
        child: Column(
          children: [
            _buildTabs(),
            _buildTabContent(context, provider),
          ],
          ),
        ),
      );
    } else {
      // For desktop/tablet: use TabBarView with Expanded
      return Container(
        color: const Color(0xFFF5F6F8),
        child: Column(
        children: [
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
        ),
      );
    }
  }

  Widget _buildTabContent(BuildContext context, DashboardProvider provider) {
    // Listen to tab changes to rebuild content
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        if (_tabController.index == 0) {
          return _buildAllPeopleView(context, provider);
        } else {
          return _buildAllTeamsView(context, provider);
        }
      },
    );
  }

  Widget _buildTabs() {
    final isMobile = ResponsiveUtils.isMobile(context);
    return Padding(
      padding: EdgeInsets.only(
        left: isMobile ? AppSpacing.md : AppSpacing.xl,
        right: isMobile ? AppSpacing.md : AppSpacing.xl,
        top: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _buildTabButton(
            index: 0,
            icon: Icons.people,
            label: 'All People',
            isMobile: isMobile,
          ),
          SizedBox(width: isMobile ? AppSpacing.md : AppSpacing.lg),
          _buildTabButton(
            index: 1,
            icon: Icons.groups,
            label: 'All Teams',
            isMobile: isMobile,
          ),
        ],
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
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: isSelected ? 40 : 0,
              height: isSelected ? 2.5 : 0,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
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

    return Padding(
      padding: ResponsiveUtils.getPadding(context),
      child: isMobile 
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPeopleHeaderSection(context, provider, isMobile: true),
              const SizedBox(height: AppSpacing.lg),
              _buildPeopleSearchSection(isMobile: true),
              const SizedBox(height: AppSpacing.lg),
              _buildPeopleContent(context, provider, filteredUsers, isMobile: true),
            ],
          )
        : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              _buildPeopleHeaderSection(context, provider, isMobile: false),
              const SizedBox(height: AppSpacing.lg),
              _buildPeopleSearchSection(isMobile: false),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: _buildPeopleContent(context, provider, filteredUsers, isMobile: false),
              ),
            ],
          ),
    );
  }

  Widget _buildPeopleHeaderSection(BuildContext context, DashboardProvider provider, {required bool isMobile}) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildPeopleHeaderTexts(context)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FutureBuilder<bool>(
            future: RBACUtils.isAdmin(),
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AppButton(
                    onPressed: () => _showInviteUserDialog(context),
                    variant: AppButtonVariant.primary,
                    fullWidth: true,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.send, size: 18, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Invite User', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      );
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildPeopleHeaderTexts(context)),
        const SizedBox(width: AppSpacing.md),
        FutureBuilder<bool>(
          future: RBACUtils.isAdmin(),
          builder: (context, snapshot) {
            if (snapshot.data == true) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AppButton(
                  onPressed: () => _showInviteUserDialog(context),
                  variant: AppButtonVariant.primary,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.send, size: 18, color: Colors.white),
                      SizedBox(width: 6),
                      Text('Invite User', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildPeopleSearchSection({required bool isMobile}) {
    if (isMobile) {
      return Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: AppSearchInput(
              controller: _searchController,
              placeholder: 'Search by name or email...',
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
            const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: AppSelect<String>(
              placeholder: 'All Status',
              options: SelectOption.fromStringList([
                'All',
                'Active',
                'On leave',
                'Inactive',
              ]),
              selectedOptionBuilder: (context, value) {
                final label = value == 'All' ? 'All Status' : value ?? 'All Status';
                return Text(label);
              },
              onChanged: (value) {
                setState(() => _statusFilter = value ?? 'All');
              },
            ),
          ),
        ],
      );
    } else {
      return Row(
            children: [
              Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
                  child: AppSearchInput(
                  controller: _searchController,
                    placeholder: 'Search by name or email...',
                    onChanged: (query) {
                      setState(() {});
                    },
              ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
          Container(
                width: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
                  child: AppSelect<String>(
                    placeholder: 'All Status',
                    options: SelectOption.fromStringList([
                      'All',
                      'Active',
                      'On leave',
                      'Inactive',
                    ]),
                    selectedOptionBuilder: (context, value) {
                      final label = _statusFilter == 'All' ? 'All Status' : _statusFilter;
                      return Text(label);
                    },
                    onChanged: (value) {
                      setState(() => _statusFilter = value ?? 'All');
                    },
                  ),
              ),
            ],
      );
    }
  }

  Widget _buildPeopleContent(BuildContext context, DashboardProvider provider, List<UserModel> filteredUsers, {required bool isMobile}) {
    if (provider.users.isEmpty && !provider.isLoading) {
      return _buildEmptyState(context, provider);
    }

    if (filteredUsers.isEmpty) {
      return _buildNoResultsState();
    }

    if (isMobile) {
      return Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    decoration: BoxDecoration(
          color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
            color: AppColors.border.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.04),
              blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
        child: ListView(
                            shrinkWrap: true,
          padding: const EdgeInsets.all(AppSpacing.md),
                            children: filteredUsers.map((user) {
            return _buildModernMobileUserCard(user, provider);
                            }).toList(),
                          ),
      );
    } else {
      return AppCard(
        backgroundColor: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.3),
                          width: 1,
                        ),
        showShadow: true,
        padding: EdgeInsets.zero,
        child: Column(
                              children: [
            _buildModernTableHeader(),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: filteredUsers.length,
                                    itemBuilder: (context, index) {
                                      final user = filteredUsers[index];
                  return _buildModernTableRow(user, provider, index == filteredUsers.length - 1);
                                    },
                                  ),
                                ),
                              ],
                            ),
      );
    }
  }

  Widget _buildEmptyState(BuildContext context, DashboardProvider provider) {
    return Center(
      child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl * 2),
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
                fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
            Text(
                            'Add your first user to get started.',
                            style: TextStyle(
                              color: AppColors.textMuted,
                fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
            FutureBuilder<bool>(
              future: RBACUtils.isAdmin(),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: AppButton(
                      onPressed: () => _showInviteUserDialog(context),
                      variant: AppButtonVariant.primary,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.send, size: 18, color: Colors.white),
                          SizedBox(width: 6),
                          Text('Invite User', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
                      ],
                    ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl * 2),
                              child: Text(
                                  'No employees match the current filters.',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
            fontSize: 14,
            ),
          ),
        ),
    );
  }

  Widget _buildAllTeamsView(
      BuildContext context, DashboardProvider provider) {
    final filteredTeams = _filteredTeams(provider.teams);
    final isMobile = ResponsiveUtils.isMobile(context);

    return SingleChildScrollView(
      child: Padding(
      padding: ResponsiveUtils.getPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and Create Team button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTeamHeaderTexts(isMobile)),
              if (!isMobile) ...[
                const SizedBox(width: AppSpacing.md),
                PermissionWrapper(
                  permission: 'create',
                  resource: 'team',
                  child: AppButton(
                    variant: AppButtonVariant.outline,
                    onPressed: () => _showAddTeamDialog(context, provider),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.group_add, size: 18),
                        SizedBox(width: 8),
                        Text('Create Team'),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: AppSpacing.sm),
            PermissionWrapper(
              permission: 'create',
              resource: 'team',
              child: AppButton(
                variant: AppButtonVariant.outline,
                onPressed: () => _showAddTeamDialog(context, provider),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.group_add, size: 18),
                    SizedBox(width: 8),
                    Text('Create Team'),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          // Search bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: AppSearchInput(
            controller: _teamSearchController,
            placeholder: 'Search',
            onChanged: (value) {
              setState(() {});
            },
              ),
          ),
          const SizedBox(height: AppSpacing.md),
            // Filter bar
          if (!isMobile) _buildFilterBar(),
          if (isMobile) ...[
            _buildMobileFilterBar(),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
          // Teams grid/list
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
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Create a team to collaborate with your members.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      variant: AppButtonVariant.outline,
                      onPressed: () => _showAddTeamDialog(context, provider),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.group_add, size: 20),
                          SizedBox(width: 8),
                          Text('Create Team'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
              _isGridView
                  ? _buildTeamsGrid(filteredTeams, provider, context, isMobile)
                  : _buildTeamsList(filteredTeams, provider, context),
            const SizedBox(height: AppSpacing.xl),
        ],
        ),
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
    var filtered = teams;
    
    // Filter by search query
    if (query.isNotEmpty) {
      filtered = filtered.where((team) => team.name.toLowerCase().contains(query)).toList();
    }
    
    // Filter by created date
    if (_createdFilter != 'All') {
      final now = DateTime.now();
      filtered = filtered.where((team) {
        switch (_createdFilter) {
          case 'Today':
            final today = DateTime(now.year, now.month, now.day);
            return team.createdAt.isAfter(today);
          case 'This Week':
            final weekAgo = now.subtract(const Duration(days: 7));
            return team.createdAt.isAfter(weekAgo);
          case 'This Month':
            final monthAgo = now.subtract(const Duration(days: 30));
            return team.createdAt.isAfter(monthAgo);
          default:
            return true;
        }
      }).toList();
    }
    
    // Sort teams alphabetically and by other criteria
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'Default':
          // Default: alphabetical by name (A-Z)
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case 'A - Z':
          // Case-insensitive alphabetical sort (A-Z)
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case 'Z - A':
          // Case-insensitive alphabetical sort (Z-A)
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case 'Most Members':
          // Most members first (descending)
          return b.memberIds.length.compareTo(a.memberIds.length);
        case 'Least Members':
          // Least members first (ascending)
          return a.memberIds.length.compareTo(b.memberIds.length);
        default:
          // Default: alphabetical by name
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
    });
    
    return filtered;
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
      children: [
        _buildFilterDropdown('Created', _createdFilter, ['All', 'Today', 'This Week', 'This Month'], (value) {
          setState(() => _createdFilter = value);
        }),
        const SizedBox(width: AppSpacing.sm),
          _buildSortDropdown(),
        const Spacer(),
        // View toggle buttons
        Row(
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

  Widget _buildMobileFilterBar() {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        _buildFilterDropdown('Created', _createdFilter, ['All', 'Today', 'This Week', 'This Month'], (value) {
          setState(() => _createdFilter = value);
        }),
        _buildSortDropdown(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildViewToggleButton(Icons.grid_view, true),
            const SizedBox(width: AppSpacing.xs),
            _buildViewToggleButton(Icons.view_list, false),
          ],
        ),
      ],
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
      onChanged: (newValue) {
        if (newValue != null) {
          onChanged(newValue);
        }
      },
    );
  }

  Widget _buildSortDropdown() {
    final sortOptions = ['Default', 'A - Z', 'Z - A', 'Most Members', 'Least Members'];
    return AppSelect<String>(
      placeholder: 'Sort',
      value: _sortBy,
      options: sortOptions.map((option) {
        final isSelected = option == _sortBy;
        return SelectOption<String>(
          value: option,
          label: option,
          icon: isSelected ? Icons.check : null,
        );
      }).toList(),
      selectedOptionBuilder: (context, selectedValue) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sort',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              selectedValue ?? _sortBy,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        );
      },
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() => _sortBy = newValue);
        }
      },
    );
  }

  Widget _buildViewToggleButton(IconData icon, bool isGrid) {
    final isSelected = _isGridView == isGrid;
    return GestureDetector(
      onTap: () {
        setState(() => _isGridView = isGrid);
      },
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

  Widget _buildTeamsGrid(List<Team> teams, DashboardProvider provider, BuildContext context, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isMobile 
            ? 2 
            : (constraints.maxWidth > 1600 ? 6 
                : constraints.maxWidth > 1400 ? 5 
                : constraints.maxWidth > 1000 ? 4 
                : constraints.maxWidth > 800 ? 3 
                : 2);
        final spacing = AppSpacing.md;
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(spacing),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 0.9,
          ),
          itemCount: teams.length,
          itemBuilder: (context, index) {
            final team = teams[index];
            return _buildModernTeamCard(team, provider, context);
          },
        );
      },
    );
  }

  Widget _buildTeamsList(List<Team> teams, DashboardProvider provider, BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemCount: teams.length,
      itemBuilder: (context, index) {
        final team = teams[index];
        return _buildModernTeamListCard(team, provider, context);
      },
    );
  }

  Widget _buildModernTeamListCard(Team team, DashboardProvider provider, BuildContext context) {
    final initial = team.name.isNotEmpty ? team.name[0].toUpperCase() : '?';
    
    return AppCard(
      backgroundColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: AppColors.border.withValues(alpha: 0.3),
        width: 1,
      ),
      showShadow: true,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeamDetailPage(teamId: team.id),
          ),
        );
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primarySoft,
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
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
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${team.memberIds.length} ${team.memberIds.length == 1 ? 'member' : 'members'}',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<Map<String, bool>>(
            future: _getTeamPermissions(),
            builder: (context, snapshot) {
              final canUpdate = snapshot.data?['update'] ?? false;
              final canDelete = snapshot.data?['delete'] ?? false;
              
              return PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                itemBuilder: (context) {
                  final items = <PopupMenuEntry<String>>[];
                  
                  if (canUpdate) {
                    items.add(
                      PopupMenuItem(
                        value: 'add',
                        child: Row(
                          children: [
                            const Icon(Icons.person_add_alt_1, size: 16),
                            const SizedBox(width: AppSpacing.xs),
                            const Text('Add Members', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                    items.add(
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 16),
                            const SizedBox(width: AppSpacing.xs),
                            const Text('Edit', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  if (canDelete) {
                    items.add(
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                            const SizedBox(width: AppSpacing.xs),
                            Text('Delete', style: TextStyle(color: AppColors.danger, fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return items;
                },
                onSelected: (value) {
                  if (value == 'add') {
                    _showTeamMembersDialog(context, provider, team);
                  } else if (value == 'edit') {
                    _showEditTeamDialog(context, provider, team);
                  } else if (value == 'delete') {
                    _confirmDeleteTeam(context, provider, team);
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModernTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md + 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: const [
          Expanded(flex: 2, child: _ModernHeaderCell('Name')),
          Expanded(flex: 2, child: _ModernHeaderCell('Role')),
          Expanded(flex: 2, child: _ModernHeaderCell('Email')),
          Expanded(child: _ModernHeaderCell('Status')),
          SizedBox(width: 120, child: _ModernHeaderCell('Actions')),
        ],
      ),
    );
  }

  Widget _buildModernMobileUserCard(UserModel user, DashboardProvider provider) {
    return AppCard(
      backgroundColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
        border: Border.all(
        color: AppColors.border.withValues(alpha: 0.3),
          width: 1,
        ),
      showShadow: true,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
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
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _ModernStatusBadge(status: user.status),
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
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.role,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                  children: [
                  _buildActionButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Edit',
                    onPressed: () => _showAddUserDialog(context, provider, user: user),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _buildActionButton(
                    icon: Icons.delete_outline,
                    tooltip: 'Delete',
                        onPressed: () => _confirmDelete(context, provider, user),
                    isDestructive: true,
                    ),
                  ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernTableRow(UserModel user, DashboardProvider provider, bool isLast) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        hoverColor: const Color(0xFFF9FAFB),
        child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
            vertical: AppSpacing.md + 2,
      ),
      decoration: BoxDecoration(
            color: Colors.white,
        borderRadius: isLast
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              )
            : null,
        border: Border(
          top: BorderSide(
                color: AppColors.border.withValues(alpha: 0.2),
                width: 1,
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
                      radius: 20,
                  backgroundColor: AppColors.primarySoft,
                  child: Text(
                    user.name.isNotEmpty
                        ? user.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                    ),
                  ),
                ),
                    const SizedBox(width: AppSpacing.md),
                Expanded(
                      child: Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
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
                    fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              user.email,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
                  style: TextStyle(
                color: AppColors.textMuted,
                    fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
                  child: _ModernStatusBadge(status: user.status),
            ),
          ),
          SizedBox(
            width: 120,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                    _buildActionButton(
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit',
                      onPressed: () => _showAddUserDialog(context, provider, user: user),
                ),
                    const SizedBox(width: AppSpacing.xs),
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      tooltip: 'Delete',
                  onPressed: () => _confirmDelete(context, provider, user),
                      isDestructive: true,
                    ),
                  ],
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return ShadTooltip(
      builder: (context) => Text(tooltip),
      child: ShadIconButton.ghost(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 18,
          color: isDestructive ? AppColors.danger : AppColors.textMuted,
        ),
      ),
    );
  }

  void _showInviteUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const InviteUserDialog(),
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

  Widget _buildPeopleHeaderTexts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'People Directory',
          style: TextStyle(
            fontSize: ResponsiveUtils.getFontSize(
              context,
              mobile: 24,
              tablet: 26,
              desktop: 24,
            ),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Manage and view all users',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: ResponsiveUtils.getFontSize(
              context,
              mobile: 14,
              tablet: 15,
              desktop: 14,
            ),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamHeaderTexts(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Teams',
          style: TextStyle(
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage members and team settings',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: isMobile ? 12 : 13,
          ),
        ),
      ],
    );
  }

  // Modern white team card using AppCard
  Widget _buildModernTeamCard(Team team, DashboardProvider provider, BuildContext context) {
    final initial = team.name.isNotEmpty ? team.name[0].toUpperCase() : '?';
    
    return AppCard(
      backgroundColor: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: AppColors.border.withValues(alpha: 0.3),
        width: 1,
      ),
      showShadow: true,
      padding: const EdgeInsets.all(AppSpacing.md),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeamDetailPage(teamId: team.id),
            ),
          );
        },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primarySoft,
                        child: Text(
                          initial,
                          style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    FutureBuilder<Map<String, bool>>(
                      future: _getTeamPermissions(),
                      builder: (context, snapshot) {
                        final canUpdate = snapshot.data?['update'] ?? false;
                        final canDelete = snapshot.data?['delete'] ?? false;

                        return PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          color: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          itemBuilder: (context) {
                            final items = <PopupMenuEntry<String>>[];

                            if (canUpdate) {
                              items.add(
                                PopupMenuItem(
                                  value: 'add',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person_add_alt_1, size: 16),
                                      const SizedBox(width: AppSpacing.xs),
                                      const Text('Add Members', style: TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                              );
                              items.add(
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.edit_outlined, size: 16),
                                      const SizedBox(width: AppSpacing.xs),
                                      const Text('Edit', style: TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                              );
                            }

                            if (canDelete) {
                              items.add(
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                                      const SizedBox(width: AppSpacing.xs),
                                      Text('Delete', style: TextStyle(color: AppColors.danger, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return items;
                          },
                          onSelected: (value) {
                            if (value == 'add') {
                              _showTeamMembersDialog(context, provider, team);
                            } else if (value == 'edit') {
                              _showEditTeamDialog(context, provider, team);
                            } else if (value == 'delete') {
                              _confirmDeleteTeam(context, provider, team);
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  team.name,
                  style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          const SizedBox(height: 4),
                    Text(
                      '${team.memberIds.length} ${team.memberIds.length == 1 ? 'member' : 'members'}',
            style: TextStyle(
              color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Delete team'),
        child: Text('Delete ${team.name}?'),
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
    }
  }

  void _confirmDelete(
    BuildContext context,
    DashboardProvider provider,
    UserModel user,
  ) {
    showDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Remove employee'),
        child: Text('Are you sure you want to remove ${user.name}?'),
        actions: [
          AppButton(
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          AppButton(
            variant: AppButtonVariant.destructive,
            onPressed: () async {
              Navigator.of(context).pop();
              await provider.deleteUser(user.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${user.name} removed'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _ModernHeaderCell extends StatelessWidget {
  const _ModernHeaderCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        fontSize: 12,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _ModernStatusBadge extends StatelessWidget {
  const _ModernStatusBadge({required this.status});

  final String status;

  Color get _backgroundColor {
    switch (status) {
      case 'Active':
        return const Color(0xFFD1FAE5);
      case 'On leave':
        return const Color(0xFFFEF3C7);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color get _textColor {
    switch (status) {
      case 'Active':
        return const Color(0xFF065F46);
      case 'On leave':
        return const Color(0xFF92400E);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _textColor,
          fontWeight: FontWeight.w500,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
