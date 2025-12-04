import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/shadcn/shadcn.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/user_model.dart';
import '../../models/team_model.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/shadcn/shadcn_widgets.dart';
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
  bool _isGridView = true; // Grid view by default (ClickUp style)
  String _membersFilter = 'All';
  String _createdFilter = 'All';
  String _creatorFilter = 'All';
  String _sortBy = 'Name';

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
      return SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context, provider),
            _buildTabs(),
            _buildTabContent(context, provider),
          ],
        ),
      );
    } else {
      // For desktop/tablet: use TabBarView with Expanded
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
                      mobile: 20,
                      tablet: 22,
                      desktop: 24,
                    ),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                    height: 1.2,
            ),
          ),
                const SizedBox(height: AppSpacing.xs / 2),
                Text(
                  'Manage your team members and groups',
                  style: TextStyle(
                color: AppColors.textMuted,
                    fontSize: ResponsiveUtils.getFontSize(
                      context,
                      mobile: 12,
                      tablet: 13,
                      desktop: 13,
                    ),
                    height: 1.4,
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
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPeopleHeaderTexts(context),
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ShadIconButton(
                          onPressed: () => _showAddUserDialog(context, provider),
                          icon: const Icon(Icons.add, size: 18),
                        ),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildPeopleHeaderTexts(context)),
                      const SizedBox(width: AppSpacing.md),
                      AppButton(
                        variant: AppButtonVariant.outline,
                        onPressed: () => _showAddUserDialog(context, provider),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 20),
                            SizedBox(width: 8),
                            Text('Add User'),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (isMobile) ...[
            AppSearchInput(
              controller: _searchController,
              placeholder: 'Search by name or email...',
              onChanged: (value) {
                setState(() {});
              },
          ),
            const SizedBox(height: AppSpacing.md),
            AppSelect<String>(
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
          ] else ...[
          Row(
            children: [
              Expanded(
                  child: AppSearchInput(
                  controller: _searchController,
                    placeholder: 'Search by name or email...',
                    onChanged: (query) {
                      setState(() {});
                    },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 160,
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
                    width: 160,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Add your first user to get started.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                    ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      variant: AppButtonVariant.outline,
                      onPressed: () => _showAddUserDialog(context, provider),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 20),
                          SizedBox(width: 8),
                          Text('Add User'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            isMobile
                ? Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
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
                                    fontSize: 13,
                                  ),
                              ),
                            ),
                          )
                        : ListView(
                            shrinkWrap: true,
                            children: filteredUsers.map((user) {
                              return _buildMobileUserCard(user, provider);
                            }).toList(),
                          ),
                  )
                : Expanded(
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
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl * 2),
                              child: const Center(
                                child: Text(
                                  'No employees match the current filters.',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                _buildTableHeader(),
                                Expanded(
                                  child: ListView.builder(
                                    shrinkWrap: false,
                                    itemCount: filteredUsers.length,
                                    itemBuilder: (context, index) {
                                      final user = filteredUsers[index];
                                      final isLast = index == filteredUsers.length - 1;
                                      return _buildTableRow(user, provider, isLast: isLast);
                                    },
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
          if (isMobile) const SizedBox(height: AppSpacing.xl),
        ],
      )
      : SizedBox.expand(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildPeopleHeaderTexts(context)),
                      const SizedBox(width: AppSpacing.md),
                      AppButton(
                        variant: AppButtonVariant.outline,
                        onPressed: () => _showAddUserDialog(context, provider),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 20),
                            SizedBox(width: 8),
                            Text('Add User'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                  child: AppSearchInput(
                  controller: _searchController,
                    placeholder: 'Search by name or email...',
                    onChanged: (value) {
                      setState(() {});
                    },
                ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(
                      width: 160,
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
                          width: 160,
                        ),
                    ),
                  ],
                ),
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
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          const Text(
                            'Add your first user to get started.',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AppButton(
                            variant: AppButtonVariant.outline,
                            onPressed: () => _showAddUserDialog(context, provider),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 20),
                                SizedBox(width: 8),
                                Text('Add User'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 300,
                    ),
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
                                    fontSize: 13,
                                  ),
                              ),
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
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
          ),
        ),
    );
  }

  Widget _buildAllTeamsView(
      BuildContext context, DashboardProvider provider) {
    final filteredTeams = _filteredTeams(provider.teams);
    final isMobile = ResponsiveUtils.isMobile(context);

    return Padding(
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
                AppButton(
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
              ],
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: AppSpacing.sm),
                AppButton(
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
          ],
          const SizedBox(height: AppSpacing.md),
          // Search bar
          AppSearchInput(
            controller: _teamSearchController,
            placeholder: 'Search',
            onChanged: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: AppSpacing.md),
          // Filter bar (ClickUp style)
          if (!isMobile) _buildFilterBar(),
          if (isMobile) ...[
            _buildMobileFilterBar(),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
          // Teams grid/list
          if (filteredTeams.isEmpty)
            Expanded(
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
            Expanded(
              child: _isGridView
                  ? _buildTeamsGrid(filteredTeams, provider, context, isMobile)
                  : _buildTeamsList(filteredTeams, provider, context),
            ),
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
    var filtered = teams;
    
    // Filter by search query
    if (query.isNotEmpty) {
      filtered = filtered.where((team) => team.name.toLowerCase().contains(query)).toList();
    }
    
    // Filter by members count
    if (_membersFilter != 'All') {
      final count = int.tryParse(_membersFilter) ?? 0;
      filtered = filtered.where((team) => team.memberIds.length == count).toList();
    }
    
    // Sort teams
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'Name':
          return a.name.compareTo(b.name);
        case 'Created':
          return b.createdAt.compareTo(a.createdAt);
        case 'Members':
          return b.memberIds.length.compareTo(a.memberIds.length);
        default:
          return 0;
      }
    });
    
    return filtered;
  }

  Widget _buildFilterBar() {
    return Row(
      children: [
        _buildFilterDropdown('Members', _membersFilter, ['All', '0', '1', '2', '3', '4', '5+'], (value) {
          setState(() => _membersFilter = value);
        }),
        const SizedBox(width: AppSpacing.sm),
        _buildFilterDropdown('Created', _createdFilter, ['All', 'Today', 'This Week', 'This Month'], (value) {
          setState(() => _createdFilter = value);
        }),
        const SizedBox(width: AppSpacing.sm),
        _buildFilterDropdown('Creator', _creatorFilter, ['All', 'Me', 'Others'], (value) {
          setState(() => _creatorFilter = value);
        }),
        const SizedBox(width: AppSpacing.sm),
        _buildFilterDropdown('Sort', _sortBy, ['Name', 'Created', 'Members'], (value) {
          setState(() => _sortBy = value);
        }),
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
    );
  }

  Widget _buildMobileFilterBar() {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        _buildFilterDropdown('Members', _membersFilter, ['All', '0', '1', '2', '3', '4', '5+'], (value) {
          setState(() => _membersFilter = value);
        }),
        _buildFilterDropdown('Created', _createdFilter, ['All', 'Today', 'This Week', 'This Month'], (value) {
          setState(() => _createdFilter = value);
        }),
        _buildFilterDropdown('Sort', _sortBy, ['Name', 'Created', 'Members'], (value) {
          setState(() => _sortBy = value);
        }),
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
            : (constraints.maxWidth > 1400 ? 5 : constraints.maxWidth > 1000 ? 4 : constraints.maxWidth > 800 ? 3 : 2);
        final spacing = AppSpacing.sm;
        
        return GridView.builder(
          padding: EdgeInsets.all(spacing),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 0.85,
          ),
          itemCount: teams.length,
          itemBuilder: (context, index) {
            final team = teams[index];
            return _buildClickUpTeamCard(team, provider, context);
          },
        );
      },
    );
  }

  Widget _buildTeamsList(List<Team> teams, DashboardProvider provider, BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemCount: teams.length,
      itemBuilder: (context, index) {
        final team = teams[index];
        return _buildClickUpTeamListCard(team, provider, context);
      },
    );
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
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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
                        fontSize: 14,
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
                      builder: (context) => const Text('Edit'),
                      child: ShadIconButton(
                        onPressed: () =>
                            _showAddUserDialog(context, provider, user: user),
                        icon: const Icon(Icons.edit, size: 18),
                      ),
                    ),
                    ShadTooltip(
                      builder: (context) => const Text('Remove'),
                      child: ShadIconButton(
                        onPressed: () => _confirmDelete(context, provider, user),
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: AppColors.danger),
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
                    builder: (context) => const Text('Edit'),
                    child: ShadIconButton(
                  onPressed: () =>
                      _showAddUserDialog(context, provider, user: user),
                  icon: const Icon(Icons.edit, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: ShadTooltip(
                    builder: (context) => const Text('Remove'),
                    child: ShadIconButton(
                  onPressed: () => _confirmDelete(context, provider, user),
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: AppColors.danger),
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

  Widget _buildPeopleHeaderTexts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'People Directory',
          style: TextStyle(
            fontSize: ResponsiveUtils.getFontSize(
              context,
              mobile: 18,
              tablet: 19,
              desktop: 20,
            ),
            fontWeight: FontWeight.w600,
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
              tablet: 12,
              desktop: 13,
            ),
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

  // ClickUp-style team card with colored background
  Widget _buildClickUpTeamCard(Team team, DashboardProvider provider, BuildContext context) {
    final colors = [
      const Color(0xFF7C3AED), // Purple
      const Color(0xFF92400E), // Brown
      const Color(0xFF1E40AF), // Blue
      const Color(0xFF059669), // Green
      const Color(0xFFDC2626), // Red
      const Color(0xFFEA580C), // Orange
    ];
    final colorIndex = team.name.hashCode.abs() % colors.length;
    final cardColor = colors[colorIndex];
    final initial = team.name.isNotEmpty ? team.name[0].toUpperCase() : '?';
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeamDetailPage(teamId: team.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: cardColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        size: 18,
                        color: Colors.white70,
                      ),
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      itemBuilder: (context) => [
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
                      ],
                      onSelected: (value) {
                        if (value == 'add') {
                          _showTeamMembersDialog(context, provider, team);
                        } else if (value == 'edit') {
                          _showEditTeamDialog(context, provider, team);
                        } else if (value == 'delete') {
                          _confirmDeleteTeam(context, provider, team);
                        }
                      },
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  team.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.people,
                      size: 14,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${team.memberIds.length} ${team.memberIds.length == 1 ? 'member' : 'members'}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ClickUp-style list card
  Widget _buildClickUpTeamListCard(Team team, DashboardProvider provider, BuildContext context) {
    final colors = [
      const Color(0xFF7C3AED),
      const Color(0xFF92400E),
      const Color(0xFF1E40AF),
      const Color(0xFF059669),
      const Color(0xFFDC2626),
      const Color(0xFFEA580C),
    ];
    final colorIndex = team.name.hashCode.abs() % colors.length;
    final cardColor = colors[colorIndex];
    final initial = team.name.isNotEmpty ? team.name[0].toUpperCase() : '?';
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeamDetailPage(teamId: team.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cardColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${team.memberIds.length} ${team.memberIds.length == 1 ? 'member' : 'members'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                itemBuilder: (context) => [
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
                ],
                onSelected: (value) {
                  if (value == 'add') {
                    _showTeamMembersDialog(context, provider, team);
                  } else if (value == 'edit') {
                    _showEditTeamDialog(context, provider, team);
                  } else if (value == 'delete') {
                    _confirmDeleteTeam(context, provider, team);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamCard(Team team, DashboardProvider provider, BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeamDetailPage(teamId: team.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Icon(
                        Icons.groups,
                        size: 12,
                        color: AppColors.primary,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      itemBuilder: (context) => [
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
                      ],
                      onSelected: (value) {
                        if (value == 'add') {
                          _showTeamMembersDialog(context, provider, team);
                        } else if (value == 'edit') {
                          _showEditTeamDialog(context, provider, team);
                        } else if (value == 'delete') {
                          _confirmDeleteTeam(context, provider, team);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        team.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.1,
                        ),
                      ),
                      if (team.description.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          team.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 10,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${team.memberIds.length}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
