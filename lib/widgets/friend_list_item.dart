import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../screens/vs_mode/vs_mode_setup_screen.dart';
import '../l10n/app_localizations.dart';

/// Widget to display a friend in a list with their stats
/// Requirements: 3.2
class FriendListItem extends StatelessWidget {
  final UserModel friend;

  const FriendListItem({super.key, required this.friend});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: friend.avatarUrl != null
              ? AssetImage(friend.avatarUrl!)
              : const AssetImage('assets/app_images/avatars/avatar_1.png'),
        ),
        title: Text(friend.displayName),
        subtitle: Row(
          children: [
            const Icon(Icons.emoji_events, size: 16, color: Colors.green),
            const SizedBox(width: 4),
            Text('${friend.duelsWon} ${l10n.wins}'),
            const SizedBox(width: 16),
            const Icon(Icons.close, size: 16, color: Colors.red),
            const SizedBox(width: 4),
            Text('${friend.duelsLost} ${l10n.losses}'),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VSModeSetupScreen()),
          );
        },
      ),
    );
  }
}
