import 'package:flutter/material.dart';

import 'package:shadcn_ui/shadcn_ui.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../widgets/shadcn/shadcn_widgets.dart';
import '../../models/user_model.dart';
import '../../providers/realtime_chat_provider.dart';

class NewDirectMessageDialog extends StatefulWidget {
  const NewDirectMessageDialog({
    super.key,
    required this.users,
    required this.provider,
    required this.onConversationCreated,
  });

  final List<UserModel> users;
  final RealtimeChatProvider provider;
  final Function(String conversationId) onConversationCreated;

  @override
  State<NewDirectMessageDialog> createState() => _NewDirectMessageDialogState();
}

class _NewDirectMessageDialogState extends State<NewDirectMessageDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _users = const [];
  List<UserModel> _filteredUsers = const [];

  @override
  void initState() {
    super.initState();
    _initializeUsers();
    _searchController.addListener(_filterUsers);
  }

  void _initializeUsers() {
    final users = List<UserModel>.from(widget.users);
    _users = users;
    _filteredUsers = users;
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users
            .where((user) =>
                user.name.toLowerCase().contains(query) ||
                user.email.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _startConversation(UserModel user) async {
    try {
      final conversationId = await widget.provider.createDirectConversation(
        user.id,
        user.name,
      );

      if (mounted) {
        widget.onConversationCreated(conversationId);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting conversation: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              'New Conversation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppSearchInput(
              controller: _searchController,
              placeholder: 'Search users...',
              onChanged: (_) => _filterUsers(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              constraints: const BoxConstraints(maxHeight: 320),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(6),
              ),
              child: _filteredUsers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          'No users found',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        return InkWell(
                          onTap: () => _startConversation(user),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.2),
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
                AppButton(
                  variant: AppButtonVariant.outline,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
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

