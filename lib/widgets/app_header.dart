import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../theme/app_colors.dart';
import '../screens/settings/settings_screen.dart';

/// Reusable app header widget with streak, streak points, and profile icon
/// The profile icon opens settings when tapped
class AppHeader extends ConsumerWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final userDataAsync = userId != null
        ? ref.watch(userDataProvider(userId))
        : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return userDataAsync == null
        ? const SizedBox.shrink()
        : userDataAsync.when(
            data: (userData) {
              return SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Streak and streak points
                      Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            color: AppColors.fire,
                            size: 24,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${userData.streakCurrent}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.titleMedium?.color,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.stars, color: AppColors.warning, size: 24),
                          const SizedBox(width: 4),
                          Text(
                            '${userData.streakPoints}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.titleMedium?.color,
                            ),
                          ),
                        ],
                      ),
                      // Profile avatar with settings button
                      Tooltip(
                        message: 'Settings',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SettingsScreen(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: _buildAvatar(context, userData, isDark),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          );
  }

  /// Build avatar widget with gear indicator in corner
  Widget _buildAvatar(BuildContext context, dynamic userData, bool isDark) {
    final avatarPath = userData.avatarPath ?? userData.avatarUrl;

    return Stack(
      children: [
        // Main avatar
        if (avatarPath != null && avatarPath.isNotEmpty)
          CircleAvatar(
            radius: 18,
            backgroundColor: isDark
                ? AppColors.primaryDark
                : AppColors.primaryLightest,
            child: ClipOval(
              child: Image.asset(
                avatarPath,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.person,
                    size: 22,
                    color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                  );
                },
              ),
            ),
          )
        else
          CircleAvatar(
            radius: 18,
            backgroundColor: isDark
                ? AppColors.primaryDark
                : AppColors.primaryLightest,
            child: Icon(
              Icons.person,
              size: 22,
              color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
            ),
          ),
        // Small gear indicator in bottom-right corner
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isDark ? AppColors.primary : AppColors.primaryDark,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.backgroundDark : AppColors.background,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.settings,
              size: 10,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}


