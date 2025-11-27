import 'package:flutter/material.dart';

import '../../components/shadcn/shadcn.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/user_model.dart';
import '../../providers/realtime_chat_provider.dart';

class CreateGroupDialog extends StatefulWidget {
  const CreateGroupDialog({
    super.key,
    required this.users,
    required this.provider,
    required this.onGroupCreated,
  });

  final List<UserModel> users;
  final RealtimeChatProvider provider;
  final Function(String groupId) onGroupCreated;

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final TextEditingController _nameController = TextEditingController();
  final List<String> _selectedMemberIds = [];
  final Map<String, String> _selectedMemberNames = {};
  late final List<UserModel> _users =
      widget.users.where((user) => user.id.isNotEmpty).toList();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleMember(String userId, String userName) {
    setState(() {
      if (_selectedMemberIds.contains(userId)) {
        _selectedMemberIds.remove(userId);
        _selectedMemberNames.remove(userId);
      } else {
        _selectedMemberIds.add(userId);
        _selectedMemberNames[userId] = userName;
      }
    });
  }

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }

    try {
      final groupId = await widget.provider.createGroup(
        _nameController.text.trim(),
        _selectedMemberIds,
        _selectedMemberNames,
      );

      if (mounted) {
        widget.onGroupCreated(groupId);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating group: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Group',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ShadInput(
              controller: _nameController,
              label: 'Group Name',
              hintText: 'Enter group name...',
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Select Members',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              constraints: const BoxConstraints(maxHeight: 280),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(6),
              ),
              child: _users.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          'No members available',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final isSelected = _selectedMemberIds.contains(user.id);

                        return InkWell(
                          onTap: () => _toggleMember(user.id, user.name),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (_) => _toggleMember(user.id, user.name),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                                  child: Text(
                                    user.name.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
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
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        user.email,
                                        style: TextStyle(
                                          fontSize: 11,
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
                      },
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ShadButton(
                  onPressed: () => Navigator.of(context).pop(),
                  variant: ShadButtonVariant.outline,
                  size: ShadButtonSize.sm,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ShadButton(
                  onPressed: _createGroup,
                  variant: ShadButtonVariant.default_,
                  size: ShadButtonSize.sm,
                  child: const Text(
                    'Create Group',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

