import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/friend.dart';
import '../../models/user_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/duel_providers.dart';
import '../../providers/friends_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_header.dart';

/// FriendsScreen displaying friend code and friends list with duel challenges
/// Requirements: 10.1, 10.2, 10.4, 10.5, 15a.3, 15a.4
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
    final friendsWithDataAsync = ref.watch(friendsWithDataProvider(userId));
    final pendingRequestsAsync = ref.watch(pendingRequestsProvider(userId));

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: userDataAsync.when(
              data: (userData) {
                return Column(
                  children: [
                    // Friend code section
                    _buildFriendCodeSection(context, userData),
                    const Divider(),
                    // Pending requests section
                    pendingRequestsAsync.when(
                      data: (pendingRequests) {
                        if (pendingRequests.isNotEmpty) {
                          return Column(
                            children: [
                              _buildPendingRequestsSection(
                                context,
                                ref,
                                userId,
                                pendingRequests,
                              ),
                              const Divider(),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (error, stack) => const SizedBox.shrink(),
                    ),
                    // Friends list section
                    Expanded(
                      child: friendsWithDataAsync.when(
                        data: (friendsWithData) => _buildFriendsList(
                          context,
                          ref,
                          userId,
                          friendsWithData,
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: AppColors.error,
                              ),
                              const SizedBox(height: 16),
                              Text('Error loading friends: $error'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  ref.invalidate(friendsWithDataProvider(userId));
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
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text('Error loading user data: $error'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFriendDialog(context, ref, userId),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Friend'),
      ),
    );
  }

  Widget _buildPendingRequestsSection(
    BuildContext context,
    WidgetRef ref,
    String userId,
    List<UserModel> pendingRequests,
  ) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Friend Requests (${pendingRequests.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...pendingRequests.map((requester) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: requester.avatarPath != null
                          ? AssetImage(requester.avatarPath!)
                          : null,
                      backgroundColor: AppColors.primary,
                      child: requester.avatarPath == null
                          ? Text(
                              requester.displayName.isNotEmpty
                                  ? requester.displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: AppColors.textOnPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            requester.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Wants to be your friend',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _handleDeclineFriendRequest(
                        context,
                        ref,
                        userId,
                        requester,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: const Text('Decline'),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: () => _handleAcceptFriendRequest(
                        context,
                        ref,
                        userId,
                        requester,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Accept'),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFriendCodeSection(BuildContext context, UserModel userData) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Friend Code',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color:
                    theme.textTheme.bodySmall?.color ?? AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    userData.friendCode,
                    style: theme.textTheme.headlineMedium?.copyWith(
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
            Text(
              'Share this code with friends so they can add you',
              style: TextStyle(
                fontSize: 12,
                color:
                    theme.textTheme.bodySmall?.color ?? AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList(
    BuildContext context,
    WidgetRef ref,
    String userId,
    List<(UserModel, Friend)> friendsWithData,
  ) {
    final theme = Theme.of(context);

    if (friendsWithData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_off,
              size: 64,
              color: theme.iconTheme.color ?? AppColors.iconSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No friends yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add friends using their friend code',
              style: TextStyle(
                color:
                    theme.textTheme.bodySmall?.color ?? AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: friendsWithData.length,
      itemBuilder: (context, index) {
        final (friend, friendship) = friendsWithData[index];
        return _buildFriendTile(context, ref, userId, friend, friendship);
      },
    );
  }

  Widget _buildFriendTile(
    BuildContext context,
    WidgetRef ref,
    String userId,
    UserModel friend,
    Friend friendship,
  ) {
    final hasIncomingChallenge = friendship.hasIncomingChallenge(userId);
    final hasOutgoingChallenge = friendship.hasOutgoingChallenge(userId);
    final isAcceptedDuel = friendship.openChallenge?.isAccepted ?? false;
    final isPendingChallenge = friendship.openChallenge?.isPending ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Challenge notification banner
          if (hasIncomingChallenge && isPendingChallenge)
            // Pending challenge - show accept/decline buttons
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.sports_mma,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${friend.displayName} challenged you to a duel!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _handleChallengeResponse(
                      context,
                      ref,
                      friendship.openChallenge!.duelId,
                      userId,
                      true,
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                    child: const Text('Accept'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _handleChallengeResponse(
                      context,
                      ref,
                      friendship.openChallenge!.duelId,
                      userId,
                      false,
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                    child: const Text('Decline'),
                  ),
                ],
              ),
            )
          else if (isAcceptedDuel)
            // Accepted duel - show status based on completion (real-time)
            Consumer(
              builder: (context, ref, child) {
                final duelAsync = ref.watch(duelStreamProvider(friendship.openChallenge!.duelId));
                
                return duelAsync.when(
                  data: (duel) {
                    final isChallenger = duel.challengerId == userId;
                    final userCompleted = isChallenger 
                        ? duel.challengerCompletedAt != null
                        : duel.opponentCompletedAt != null;
                    final opponentCompleted = isChallenger
                        ? duel.opponentCompletedAt != null
                        : duel.challengerCompletedAt != null;

                    if (userCompleted) {
                  if (opponentCompleted) {
                    // Both completed - show "View Results" button
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Duel with ${friend.displayName} completed!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _viewDuelResults(
                              context,
                              friendship.openChallenge!.duelId,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              elevation: 0,
                            ),
                            child: const Text(
                              'View Results',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // User completed, waiting for opponent
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.hourglass_empty,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Waiting for ${friend.displayName} to complete',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                } else {
                  // User can start the duel
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.play_circle_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Duel with ${friend.displayName} is ready!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _startAcceptedDuel(
                            context,
                            friendship.openChallenge!.duelId,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Start Duel',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                    }
                  },
                  loading: () => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  ),
                  error: (error, stack) => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Error loading duel status',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          // Main friend tile content
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Avatar - tappable to initiate duel challenge
                // Requirements: 10.1, 10.2
                Stack(
                  children: [
                    GestureDetector(
                      onTap: isPendingChallenge 
                          ? null 
                          : () => _showDuelChallengeDialog(
                              context,
                              ref,
                              userId,
                              friend,
                            ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundImage: friend.avatarPath != null
                            ? AssetImage(friend.avatarPath!)
                            : null,
                        backgroundColor: AppColors.primary,
                        child: friend.avatarPath == null
                            ? Text(
                                friend.displayName.isNotEmpty
                                    ? friend.displayName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppColors.textOnPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              )
                            : null,
                      ),
                    ),
                    // Challenge status indicator
                    if (hasOutgoingChallenge)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.warning,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.schedule,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Friend info and stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Display streak points instead of XP
                      Text(
                        'Streak: ${friend.streakCurrent} days • ${friend.streakPoints} pts',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Head-to-head statistics
                      // Requirements: 15a.3, 15a.4
                      Text(
                        'vs You: ${friendship.getRecordString()} (${friendship.totalDuels} duels)',
                        style: TextStyle(
                          fontSize: 12,
                          color: friendship.isLeading()
                              ? AppColors.success
                              : friendship.isTied()
                                  ? AppColors.textSecondary
                                  : AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // Challenge status text
                      if (isAcceptedDuel)
                        Consumer(
                          builder: (context, ref, child) {
                            final duelAsync = ref.watch(duelStreamProvider(friendship.openChallenge!.duelId));
                            
                            return duelAsync.when(
                              data: (duel) {
                                final isChallenger = duel.challengerId == userId;
                                final userCompleted = isChallenger 
                                    ? duel.challengerCompletedAt != null
                                    : duel.opponentCompletedAt != null;
                                final opponentCompleted = isChallenger
                                    ? duel.opponentCompletedAt != null
                                    : duel.challengerCompletedAt != null;
                                
                                if (userCompleted && opponentCompleted) {
                                  return const Text(
                                    'Duel completed - tap banner to view results',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                } else if (userCompleted) {
                                  return const Text(
                                    'Waiting for opponent to complete',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.warning,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  );
                                } else {
                                  return const Text(
                                    'Duel ready - tap banner to start',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                }
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (error, stack) => const SizedBox.shrink(),
                            );
                          },
                        )
                      else if (hasIncomingChallenge && isPendingChallenge)
                        const Text(
                          'Tap banner to accept or decline',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else if (hasOutgoingChallenge && isPendingChallenge)
                        const Text(
                          'Challenge sent - waiting for response',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                // Challenge/Start/Results button
                if (isAcceptedDuel)
                  Consumer(
                    builder: (context, ref, child) {
                      final duelAsync = ref.watch(duelStreamProvider(friendship.openChallenge!.duelId));
                      
                      return duelAsync.when(
                        data: (duel) {
                          final isChallenger = duel.challengerId == userId;
                          final userCompleted = isChallenger 
                              ? duel.challengerCompletedAt != null
                              : duel.opponentCompletedAt != null;
                          final opponentCompleted = isChallenger
                              ? duel.opponentCompletedAt != null
                              : duel.challengerCompletedAt != null;
                          
                          if (userCompleted && opponentCompleted) {
                            return IconButton(
                              icon: const Icon(Icons.emoji_events),
                              color: AppColors.primary,
                              tooltip: 'View results',
                              onPressed: () => _viewDuelResults(context, friendship.openChallenge!.duelId),
                            );
                          } else if (userCompleted) {
                            return IconButton(
                              icon: const Icon(Icons.hourglass_empty),
                              color: AppColors.warning,
                              tooltip: 'Waiting for opponent',
                              onPressed: null,
                            );
                          } else {
                            return IconButton(
                              icon: const Icon(Icons.play_arrow),
                              color: AppColors.success,
                              tooltip: 'Start duel',
                              onPressed: () => _startAcceptedDuel(context, friendship.openChallenge!.duelId),
                            );
                          }
                        },
                        loading: () => IconButton(
                          icon: const Icon(Icons.hourglass_empty),
                          color: AppColors.textSecondary,
                          onPressed: null,
                        ),
                        error: (error, stack) => IconButton(
                          icon: const Icon(Icons.error_outline),
                          color: AppColors.error,
                          onPressed: null,
                        ),
                      );
                    },
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.sports_mma),
                    color: isPendingChallenge ? AppColors.textSecondary : AppColors.primary,
                    tooltip: isPendingChallenge ? 'Challenge pending' : 'Challenge to duel',
                    onPressed: isPendingChallenge ? null : () => _showDuelChallengeDialog(
                      context,
                      ref,
                      userId,
                      friend,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Handle accepting a friend request
  /// Requirements: 10.4
  Future<void> _handleAcceptFriendRequest(
    BuildContext context,
    WidgetRef ref,
    String userId,
    UserModel requester,
  ) async {
    try {
      final friendsService = ref.read(friendsServiceProvider);
      await friendsService.acceptFriendRequest(userId, requester.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are now friends with ${requester.displayName}!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept friend request: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Handle declining a friend request
  /// Requirements: 10.4
  Future<void> _handleDeclineFriendRequest(
    BuildContext context,
    WidgetRef ref,
    String userId,
    UserModel requester,
  ) async {
    try {
      final friendsService = ref.read(friendsServiceProvider);
      await friendsService.declineFriendRequest(userId, requester.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request declined'),
            backgroundColor: AppColors.textSecondary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline friend request: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Handle accepting or declining a duel challenge
  /// Requirements: 11.2, 11.3
  Future<void> _handleChallengeResponse(
    BuildContext context,
    WidgetRef ref,
    String duelId,
    String userId,
    bool accept,
  ) async {
    try {
      final duelService = ref.read(duelServiceProvider);
      
      if (accept) {
        await duelService.acceptDuel(duelId, userId);
        
        if (context.mounted) {
          // Navigate directly to duel question screen since challenge is already accepted
          Navigator.pushNamed(
            context,
            '/duel-question',
            arguments: {'duelId': duelId},
          );
        }
      } else {
        await duelService.declineDuel(duelId, userId);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Challenge declined'),
              backgroundColor: AppColors.textSecondary,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${accept ? 'accept' : 'decline'} challenge: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Start an already accepted duel
  /// Requirements: 12.1
  void _startAcceptedDuel(BuildContext context, String duelId) {
    Navigator.pushNamed(
      context,
      '/duel-question',
      arguments: {'duelId': duelId},
    );
  }

  /// View duel results when both users have completed
  /// Requirements: 13.1
  void _viewDuelResults(BuildContext context, String duelId) {
    Navigator.pushNamed(
      context,
      '/duel-result',
      arguments: {'duelId': duelId},
    );
  }

  /// Show duel challenge confirmation dialog or active duel notification
  /// Requirements: 10.2, 10.3
  Future<void> _showDuelChallengeDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
    UserModel friend,
  ) async {
    final userDataAsync = ref.read(userDataProvider(userId));
    
    userDataAsync.when(
      data: (currentUser) {
        showDialog(
          context: context,
          builder: (dialogContext) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // VS Mode display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Current user
                      _buildDialogAvatar(
                        context: context,
                        player: currentUser,
                        isYou: true,
                      ),

                      // VS text
                      Text(
                        'VS',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade400,
                          letterSpacing: 2,
                        ),
                      ),

                      // Friend
                      _buildDialogAvatar(
                        context: context,
                        player: friend,
                        isYou: false,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'Challenge ${friend.displayName}?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '5 questions • Answer at your own pace',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();
                            await _createDuelChallenge(context, ref, userId, friend);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5C9EFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Send Challenge',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  Widget _buildDialogAvatar({
    required BuildContext context,
    required UserModel player,
    required bool isYou,
  }) {
    final borderColor = const Color(0xFF00897B);

    return Column(
      children: [
        // Avatar with border
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor,
              width: 3,
            ),
          ),
          child: CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey.shade200,
            child: ClipOval(
              child: (player.avatarPath ?? player.avatarUrl) != null
                  ? Image.asset(
                      player.avatarPath ?? player.avatarUrl!,
                      fit: BoxFit.cover,
                      width: 80,
                      height: 80,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey.shade600,
                        );
                      },
                    )
                  : Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.grey.shade600,
                    ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Player name
        Text(
          isYou ? 'You' : player.displayName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Create a duel challenge
  /// Requirements: 10.2, 10.3
  Future<void> _createDuelChallenge(
    BuildContext context,
    WidgetRef ref,
    String userId,
    UserModel friend,
  ) async {
    try {
      final duelService = ref.read(duelServiceProvider);
      await duelService.createDuel(userId, friend.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Duel challenge sent to ${friend.displayName}!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create duel: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Add Friend'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your friend\'s code to add them',
              style: TextStyle(
                fontSize: 14,
                color:
                    theme.textTheme.bodySmall?.color ?? AppColors.textSecondary,
              ),
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
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error),
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

      // Send friend request
      await friendsService.sendFriendRequest(widget.userId, friendUser.id);

      // Success - close dialog and show success message
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request sent to ${friendUser.displayName}!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        // Handle specific error messages
        if (e.toString().contains('Cannot add yourself')) {
          _errorMessage = 'You cannot add yourself as a friend';
        } else if (e.toString().contains('Friend request already sent')) {
          _errorMessage = 'Friend request already sent to this user';
        } else if (e.toString().contains('Already friends')) {
          _errorMessage = 'You are already friends with this user';
        } else {
          _errorMessage = 'Failed to send friend request. Please try again.';
        }
        _isLoading = false;
      });
    }
  }
}
