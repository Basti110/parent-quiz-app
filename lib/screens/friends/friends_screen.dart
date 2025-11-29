import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../providers/friends_providers.dart';
import '../../models/user_model.dart';

/// FriendsScreen displaying friend code and friends list
/// Requirements: 10.1, 10.5
class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Friends')),
        body: const Center(child: Text('Please log in to view friends')),
      );
    }

    final userDataAsync = ref.watch(userDataProvider(userId));
    final friendsListAsync = ref.watch(friendsListProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: userDataAsync.when(
        data: (userData) {
          return Column(
            children: [
              // Friend code section
              _buildFriendCodeSection(context, userData),
              const Divider(),
              // Friends list section
              Expanded(
                child: friendsListAsync.when(
                  data: (friends) => _buildFriendsList(context, friends),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text('Error loading friends: $error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.invalidate(friendsListProvider(userId));
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading user data: $error'),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFriendDialog(context, ref, userId),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Friend'),
      ),
    );
  }

  Widget _buildFriendCodeSection(BuildContext context, UserModel userData) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Friend Code',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    userData.friendCode,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: userData.friendCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Friend code copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  tooltip: 'Copy friend code',
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Share this code with friends so they can add you',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList(BuildContext context, List<UserModel> friends) {
    if (friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No friends yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add friends using their friend code',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        return _buildFriendTile(friend);
      },
    );
  }

  Widget _buildFriendTile(UserModel friend) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue,
        child: Text(
          friend.displayName.isNotEmpty
              ? friend.displayName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        friend.displayName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text('Level ${friend.currentLevel} • ${friend.totalXp} XP'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'Weekly XP',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          Text(
            '${friend.weeklyXpCurrent}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showAddFriendDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AddFriendDialog(userId: userId),
    );
  }
}

/// AddFriendDialog for friend code input
/// Requirements: 10.2, 10.3, 10.4
class AddFriendDialog extends ConsumerStatefulWidget {
  final String userId;

  const AddFriendDialog({super.key, required this.userId});

  @override
  ConsumerState<AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends ConsumerState<AddFriendDialog> {
  final _formKey = GlobalKey<FormState>();
  final _friendCodeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _friendCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Friend'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your friend\'s code to add them',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _friendCodeController,
              decoration: const InputDecoration(
                labelText: 'Friend Code',
                hintText: 'e.g., ABC123',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.code),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a friend code';
                }
                if (value.length < 6 || value.length > 8) {
                  return 'Friend code must be 6-8 characters';
                }
                return null;
              },
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
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleAddFriend,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Friend'),
        ),
      ],
    );
  }

  Future<void> _handleAddFriend() async {
    // Clear previous error
    setState(() {
      _errorMessage = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final friendCode = _friendCodeController.text.trim().toUpperCase();
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
