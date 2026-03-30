import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/team_model.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/rbac_utils.dart';
import '../../widgets/shadcn/shadcn_widgets.dart';
import '../../widgets/permission_wrapper.dart';
import '../widgets/add_team_dialog.dart';
import '../widgets/team_members_dialog.dart';
import 'team_detail_page.dart';

class TeamView extends StatefulWidget {
  const TeamView({super.key});

  @override
  State<TeamView> createState() => _TeamViewState();
}

class _TeamViewState extends State<TeamView> {
  final TextEditingController _teamSearchController = TextEditingController();
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
  void dispose() {
    _teamSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    return Container(
      color: const Color(0xFFF5F6F8),
      child: _buildAllTeamsView(context, provider),
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

}
