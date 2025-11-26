import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/team_model.dart';
import '../../models/user_model.dart';
import '../../providers/dashboard_provider.dart';
import '../widgets/add_team_dialog.dart';
import '../widgets/team_members_dialog.dart';

class TeamDetailPage extends StatelessWidget {
  const TeamDetailPage({super.key, required this.teamId});

  final String teamId;

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        Team? team;
        try {
          team = provider.teams.firstWhere((t) => t.id == teamId);
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

        return Scaffold(
          appBar: AppBar(
            title: Text(currentTeam.name),
            actions: [
              IconButton(
                tooltip: 'Edit team',
                onPressed: () =>
                    _showEditDialog(context, provider, currentTeam),
                icon: const Icon(Icons.edit),
              ),
              IconButton(
                tooltip: 'Delete team',
                onPressed: () =>
                    _confirmDelete(context, provider, currentTeam),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentTeam.description.isEmpty
                      ? 'No description'
                      : currentTeam.description,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Members (${members.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _showMembersDialog(context, provider, currentTeam),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Add members'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: members.isEmpty
                      ? const Center(
                          child: Text('No members yet'),
                        )
                      : ListView.separated(
                          itemCount: members.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final user = members[index];
                            return ListTile(
                              leading: CircleAvatar(
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
                              title: Text(user.name),
                              subtitle: Text(user.email),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
        onSave: (memberIds) =>
            provider.updateTeamMembers(team.id, memberIds),
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
}

