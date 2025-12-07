import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_providers.dart';
import '../../providers/friends_providers.dart';
import '../../widgets/friend_list_item.dart';

/// VS Mode Friends Screen displaying friends list for VS Mode
/// Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6
class VSModeFriendsScreen extends ConsumerWidget {
  const VSModeFriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.vsMode)),
        body: Center(child: Text(l10n.loading)),
      );
    }

    final friendsAsync = ref.watch(friendsListProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.vsMode),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddFriendDialog(context, ref, userId, l10n),
            tooltip: l10n.addFriend,
          ),
        ],
      ),
      body: friendsAsync.when(
        data: (friends) {
          if (friends.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noFriends,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              return FriendListItem(friend: friends[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('${l10n.error}: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(friendsListProvider(userId));
                },
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddFriendDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => _AddFriendDialog(userId: userId, l10n: l10n),
    );
  }
}

/// Add Friend Dialog for entering friend code
/// Requirements: 3.3, 3.4
class _AddFriendDialog extends ConsumerStatefulWidget {
  final String userId;
  final AppLocalizations l10n;

  const _AddFriendDialog({required this.userId, required this.l10n});

  @override
  ConsumerState<_AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends ConsumerState<_AddFriendDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.l10n.addFriend),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: widget.l10n.friendCode,
              hintText: 'ABC123',
              border: const OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
            enabled: !_isLoading,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(widget.l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleAddFriend,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.l10n.add),
        ),
      ],
    );
  }

  Future<void> _handleAddFriend() async {
    final friendCode = _controller.text.trim().toUpperCase();

    if (friendCode.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a friend code';
      });
      return;
    }

    if (friendCode.length < 6 || friendCode.length > 8) {
      setState(() {
        _errorMessage = 'Friend code must be 6-8 characters';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final friendsService = ref.read(friendsServiceProvider);

      // Find user by friend code
      final friendUser = await friendsService.findUserByFriendCode(friendCode);

      if (friendUser == null) {
        setState(() {
          _errorMessage = 'No user found with this friend code';
          _isLoading = false;
        });
        return;
      }

      // Add friend
      await friendsService.addFriend(widget.userId, friendUser.id);

      // Success - close dialog and show success message
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${friendUser.displayName} added as friend!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        // Handle specific error messages
        if (e.toString().contains('Cannot add yourself')) {
          _errorMessage = 'You cannot add yourself as a friend';
        } else if (e.toString().contains('Already friends')) {
          _errorMessage = 'You are already friends with this user';
        } else {
          _errorMessage = 'Failed to add friend. Please try again.';
        }
        _isLoading = false;
      });
    }
  }
}
