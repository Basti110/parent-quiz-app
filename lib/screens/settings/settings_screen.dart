import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_providers.dart';
import '../../providers/locale_providers.dart';
import '../../providers/theme_providers.dart';
import '../../theme/app_colors.dart';
import 'avatar_selection_screen.dart';
import 'feedback_form_screen.dart';

/// State notifier for managing daily goal in settings
class DailyGoalNotifier extends StateNotifier<int> {
  DailyGoalNotifier(super.initialValue);

  void updateGoal(int newGoal) {
    if (newGoal >= 5 && newGoal <= 30) {
      state = newGoal;
    }
  }
}

/// Provider for daily goal state
final dailyGoalProvider =
    StateNotifierProvider.autoDispose<DailyGoalNotifier, int>((ref) {
  return DailyGoalNotifier(10); // Default value
});

/// SettingsScreen for managing account and appearance preferences
/// Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 9.1, 9.2, 9.3, 9.4, 9.5
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSaving = false;
  bool _hasInitializedGoal = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = ref.watch(currentUserIdProvider);
    final currentUserAsync = currentUserId != null
        ? ref.watch(userDataProvider(currentUserId))
        : null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: theme.cardColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Profile Card
          if (currentUserAsync != null)
            currentUserAsync.when(
              data: (user) => Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.surfaceDark : AppColors.border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isDark
                                  ? AppColors.backgroundDark
                                  : AppColors.textPrimary)
                              .withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: CircleAvatar(
                        backgroundImage: user.avatarPath != null
                            ? AssetImage(user.avatarPath!)
                            : null,
                        child: user.avatarPath == null
                            ? const Icon(Icons.person, size: 32)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Joined ${_formatDate(user.createdAt)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            )
          else
            const SizedBox.shrink(),

          const SizedBox(height: 24),

          // Daily Goal Section
          if (currentUserAsync != null)
            currentUserAsync.when(
              data: (user) {
                // Initialize daily goal provider with user's current goal only once
                // Ensure it's within valid range (5-30) and rounded to nearest 5
                if (!_hasInitializedGoal) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final validGoal = (user.dailyGoal.clamp(5, 30) / 5).round() * 5;
                    ref.read(dailyGoalProvider.notifier).updateGoal(validGoal);
                    _hasInitializedGoal = true;
                  });
                }
                return _buildDailyGoalSection(context, ref, l10n, theme, isDark, user.dailyGoal, currentUserId!);
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            )
          else
            const SizedBox.shrink(),

          if (currentUserAsync != null)
            currentUserAsync.when(
              data: (_) => const SizedBox(height: 24),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            )
          else
            const SizedBox.shrink(),

          // Section Header
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              l10n.settings.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.5,
                ),
                letterSpacing: 1.2,
              ),
            ),
          ),

          // Settings Card
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.surfaceDark : AppColors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      (isDark
                              ? AppColors.backgroundDark
                              : AppColors.textPrimary)
                          .withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Dark Mode Toggle
                _SettingsTile(
                  title: l10n.darkMode,
                  trailing: Switch(
                    value: themeMode == ThemeMode.dark,
                    onChanged: (_) {
                      ref.read(themeProvider.notifier).toggleTheme();
                    },
                    activeColor: AppColors.primary,
                  ),
                  showDivider: true,
                ),

                // Language Selection
                _SettingsTile(
                  title: l10n.language,
                  subtitle: locale.languageCode == 'de' ? 'Deutsch' : 'English',
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textTertiary,
                  ),
                  onTap: () => _showLanguageDialog(context, ref, l10n, locale),
                  showDivider: true,
                ),

                // Change Avatar
                _SettingsTile(
                  title: l10n.changeAvatar,
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textTertiary,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AvatarSelectionScreen(),
                      ),
                    );
                  },
                  showDivider: true,
                ),

                // Feedback
                _SettingsTile(
                  title: l10n.feedback,
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textTertiary,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FeedbackFormScreen(),
                      ),
                    );
                  },
                  showDivider: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Logout Button
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.surfaceDark : AppColors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      (isDark
                              ? AppColors.backgroundDark
                              : AppColors.textPrimary)
                          .withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _SettingsTile(
              title: l10n.logout,
              titleColor: AppColors.error,
              trailing: const Icon(Icons.logout, color: AppColors.error),
              onTap: () => _showLogoutDialog(context, ref, l10n),
              showDivider: false,
            ),
          ),

          const SizedBox(height: 32),

          // Version Footer
          Center(
            child: Text(
              'ParentWise v1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build daily goal adjustment section
  /// Requirements: 9.1, 9.2, 9.3
  Widget _buildDailyGoalSection(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ThemeData theme,
    bool isDark,
    int currentGoal,
    String userId,
  ) {
    final dailyGoal = ref.watch(dailyGoalProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            l10n.dailyGoal.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyMedium?.color?.withValues(
                alpha: 0.5,
              ),
              letterSpacing: 1.2,
            ),
          ),
        ),

        // Daily Goal Card
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.surfaceDark : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    (isDark
                            ? AppColors.backgroundDark
                            : AppColors.textPrimary)
                        .withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.dailyGoalDescription,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Current value display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.questionsPerDay,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$dailyGoal',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
                  thumbColor: AppColors.primary,
                  overlayColor: AppColors.primary.withValues(alpha: 0.2),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: dailyGoal.toDouble().clamp(5.0, 30.0),
                  min: 5,
                  max: 30,
                  divisions: 5,
                  onChanged: (value) {
                    // Round to nearest 5
                    final roundedValue = (value / 5).round() * 5;
                    ref
                        .read(dailyGoalProvider.notifier)
                        .updateGoal(roundedValue);
                  },
                ),
              ),

              // Min/Max labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '5',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  Text(
                    '30',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving || dailyGoal == currentGoal
                      ? null
                      : () => _saveDailyGoal(context, ref, l10n, userId, dailyGoal),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textOnPrimary,
                            ),
                          ),
                        )
                      : Text(
                          l10n.save,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Save daily goal to Firebase
  /// Requirements: 9.4, 9.5
  Future<void> _saveDailyGoal(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String userId,
    int newGoal,
  ) async {
    // Validate before saving
    if (newGoal < 5 || newGoal > 30 || newGoal % 5 != 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.invalidDailyGoal),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final userService = ref.read(userServiceProvider);
      await userService.updateDailyGoal(userId, newGoal);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.dailyGoalUpdated),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Recently';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  /// Show dialog to select language
  void _showLanguageDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Locale currentLocale,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(l10n.languageEnglish),
              value: 'en',
              groupValue: currentLocale.languageCode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(localeProvider.notifier).setLocale(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: Text(l10n.languageGerman),
              value: 'de',
              groupValue: currentLocale.languageCode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(localeProvider.notifier).setLocale(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  /// Show logout confirmation dialog
  void _showLogoutDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.confirmLogout),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final authService = ref.read(authServiceProvider);
                await authService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.error}: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }
}

/// Custom settings tile widget matching the design theme
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = false,
    this.titleColor,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: showDivider
              ? BorderRadius.zero
              : const BorderRadius.all(Radius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: titleColor ?? theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? AppColors.surfaceDark : AppColors.borderLight,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}
