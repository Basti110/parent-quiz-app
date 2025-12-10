import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/duel_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/duel_providers.dart';
import '../../theme/app_colors.dart';

/// DuelChallengeScreen shows a pending duel challenge and allows accept/decline
/// Requirements: 11.1, 11.2, 11.3
class DuelChallengeScreen extends ConsumerStatefulWidget {
  const DuelChallengeScreen({super.key});

  @override
  ConsumerState<DuelChallengeScreen> createState() =>
      _DuelChallengeScreenState();
}

class _DuelChallengeScreenState extends ConsumerState<DuelChallengeScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final duel = args['duel'] as DuelModel;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // If duel is already accepted, navigate to question screen
    if (duel.status == DuelStatus.accepted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            '/duel-question',
            arguments: {'duelId': duel.id},
          );
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If duel is not pending, show error
    if (duel.status != DuelStatus.pending) {
      return Scaffold(
        appBar: AppBar(title: const Text('Duel Challenge')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'This challenge is no longer available',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Duel Challenge'),
        elevation: 0,
      ),
      body: FutureBuilder<UserModel>(
        future: ref.read(userServiceProvider).getUserData(duel.challengerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading challenger data',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          final challenger = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Challenge header
                Text(
                  'You\'ve been challenged!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Challenger avatar and name
                Center(
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDarkMode
                                ? AppColors.primaryLight
                                : AppColors.primary,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isDarkMode
                                      ? AppColors.primaryLight
                                      : AppColors.primary)
                                  .withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: challenger.avatarUrl != null
                              ? Image.asset(
                                  challenger.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildDefaultAvatar(isDarkMode);
                                  },
                                )
                              : _buildDefaultAvatar(isDarkMode),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Challenger name
                      Text(
                        challenger.displayName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Challenge details
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDarkMode
                          ? AppColors.textSecondary.withValues(alpha: 0.2)
                          : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        context,
                        Icons.quiz_outlined,
                        'Questions',
                        '5 questions',
                        isDarkMode,
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        context,
                        Icons.timer_outlined,
                        'Time',
                        'Answer at your own pace',
                        isDarkMode,
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        context,
                        Icons.emoji_events_outlined,
                        'Winner',
                        'Highest score wins',
                        isDarkMode,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Accept button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _acceptDuel(duel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode
                          ? AppColors.primaryDark
                          : AppColors.textPrimary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'ACCEPT CHALLENGE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Decline button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isLoading ? null : () => _declineDuel(duel),
                    style: TextButton.styleFrom(
                      foregroundColor: isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDefaultAvatar(bool isDarkMode) {
    return Container(
      color: isDarkMode
          ? AppColors.textSecondary.withValues(alpha: 0.2)
          : AppColors.borderLight,
      child: Icon(
        Icons.person,
        size: 60,
        color: isDarkMode
            ? AppColors.textSecondaryDark
            : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    bool isDarkMode,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (isDarkMode ? AppColors.primaryLight : AppColors.primary)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDarkMode ? AppColors.primaryLight : AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _acceptDuel(DuelModel duel) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final duelService = ref.read(duelServiceProvider);
      await duelService.acceptDuel(duel.id, userId);

      if (mounted) {
        // Navigate to duel question screen
        Navigator.of(context).pushReplacementNamed(
          '/duel-question',
          arguments: {'duelId': duel.id},
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept duel: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _declineDuel(DuelModel duel) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final duelService = ref.read(duelServiceProvider);
      await duelService.declineDuel(duel.id, userId);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duel declined')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline duel: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
