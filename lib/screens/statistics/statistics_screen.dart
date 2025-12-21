import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../providers/statistics_providers.dart';
import '../../models/user_statistics.dart';
import '../../models/category_statistics.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_header.dart';

/// Statistics screen displaying user progress and category-level statistics
/// Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 5.2
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final l10n = AppLocalizations.of(context)!;

    if (userId == null) {
      return Scaffold(
        body: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: Center(
                child: Text(l10n.userNotAuthenticated),
              ),
            ),
          ],
        ),
      );
    }

    final statisticsAsync = ref.watch(userStatisticsProvider(userId));

    return Scaffold(
      body: Column(
        children: [
          // App header with streak, points, and avatar
          const AppHeader(),
          
          // Main content
          Expanded(
            child: statisticsAsync.when(
              data: (statistics) => _buildContent(context, statistics, l10n),
              loading: () => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(l10n.loadingStatistics),
                  ],
                ),
              ),
              error: (error, stack) => _buildError(context, ref, userId, error),
            ),
          ),
        ],
      ),
    );
  }

  /// Build main content with statistics
  Widget _buildContent(BuildContext context, UserStatistics statistics, AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page title
            Text(
              l10n.statistics,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 24),

            // Overall statistics card
            _buildOverallStatistics(context, statistics),

            const SizedBox(height: 24),

            // Category statistics section
            _buildCategoryStatisticsSection(context, statistics),
          ],
        ),
      ),
    );
  }

  /// Build overall statistics card
  /// Requirements: 3.1, 3.2, 3.3
  Widget _buildOverallStatistics(
    BuildContext context,
    UserStatistics statistics,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.overallProgress,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Answered questions with hint
            _buildStatRowWithHint(
              context,
              icon: Icons.check_circle_outline,
              iconColor: AppColors.primary,
              label: l10n.questionsAnswered,
              value: '${statistics.totalQuestionsAnswered}',
              hint: 'Fragen, die du korrekt beantwortet hast',
            ),

            const SizedBox(height: 12),

            // Mastered questions with hint
            _buildStatRowWithHint(
              context,
              icon: Icons.star_outline,
              iconColor: AppColors.warning,
              label: l10n.questionsMastered,
              value: '${statistics.totalQuestionsMastered}',
              hint: 'Fragen, die du 3x oder öfter richtig beantwortet hast',
            ),

            const SizedBox(height: 12),

            // Seen questions
            _buildStatRow(
              context,
              icon: Icons.visibility_outlined,
              iconColor: AppColors.info,
              label: l10n.questionsSeen,
              value: '${statistics.totalQuestionsSeen}',
            ),
          ],
        ),
      ),
    );
  }

  /// Build a single statistic row
  Widget _buildStatRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Build a single statistic row with hint tooltip
  Widget _buildStatRowWithHint(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String hint,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _showHintDialog(context, label, hint),
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Build category statistics section
  /// Requirements: 3.4, 5.2
  Widget _buildCategoryStatisticsSection(
    BuildContext context,
    UserStatistics statistics,
  ) {
    final l10n = AppLocalizations.of(context)!;

    if (statistics.categoryStats.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Text(
              l10n.noCategoryStatistics,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.byCategory,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Category statistics cards
        ...statistics.categoryStats.map((categoryStat) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildCategoryCard(context, categoryStat),
          );
        }),
      ],
    );
  }

  /// Build a single category statistics card
  /// Requirements: 5.2, 3.5
  Widget _buildCategoryCard(
    BuildContext context,
    CategoryStatistics categoryStat,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header with icon and title
            Row(
              children: [
                // Category icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/app_images/categories/${categoryStat.categoryIconName}.png',
                      width: 32,
                      height: 32,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.category,
                          color: AppColors.primary,
                          size: 32,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Category title
                Expanded(
                  child: Text(
                    categoryStat.categoryTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Statistics
            _buildCategoryStatRowWithHint(
              context,
              label: l10n.answered,
              value: categoryStat.questionsAnswered,
              total: categoryStat.totalQuestions,
              hint: 'Korrekt beantwortete Fragen',
            ),

            const SizedBox(height: 8),

            _buildCategoryStatRowWithHint(
              context,
              label: l10n.mastered,
              value: categoryStat.questionsMastered,
              total: categoryStat.totalQuestions,
              hint: '3x oder öfter richtig beantwortet',
            ),

            const SizedBox(height: 12),

            // Progress bar for answered questions
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.progress,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${(categoryStat.percentageAnswered * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: categoryStat.percentageAnswered,
                  backgroundColor: isDark
                      ? AppColors.textSecondary.withValues(alpha: 0.3)
                      : AppColors.borderLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build a category statistic row
  Widget _buildCategoryStatRow(
    BuildContext context, {
    required String label,
    required int value,
    required int total,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          '$value / $total',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Show hint dialog when info icon is tapped
  void _showHintDialog(BuildContext context, String title, String hint) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(hint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.buttonOk),
          ),
        ],
      ),
    );
  }

  /// Build a category statistic row with hint tooltip
  Widget _buildCategoryStatRowWithHint(
    BuildContext context, {
    required String label,
    required int value,
    required int total,
    required String hint,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _showHintDialog(context, label, hint),
              child: Icon(
                Icons.info_outline,
                size: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          '$value / $total',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Build error state with retry button
  /// Requirements: 3.4
  Widget _buildError(
    BuildContext context,
    WidgetRef ref,
    String userId,
    Object error,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.failedToLoadStatistics,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.pleaseTryAgain,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(userStatisticsProvider(userId));
              },
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
