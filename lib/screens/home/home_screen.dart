import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../providers/quiz_providers.dart';
import '../../widgets/category_card.dart';
import '../../l10n/app_localizations.dart';
import '../quiz/quiz_length_screen.dart';

/// HomeScreen (Dashboard) with header, hero image, daily goal, categories, and action button
/// Requirements: 2.1, 2.2, 2.5, 2.6, 2.7
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final l10n = AppLocalizations.of(context)!;

    // Watch user data if userId is available
    final userDataAsync = userId != null
        ? ref.watch(userDataProvider(userId))
        : null;

    // Watch categories
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      body: userDataAsync == null
          ? const Center(child: CircularProgressIndicator())
          : userDataAsync.when(
              data: (userData) => SafeArea(
                child: Column(
                  children: [
                    // Top bar with level/streak and XP
                    _buildTopBar(context, userData, l10n),

                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Hero section with dashboard image and greeting
                            _buildHeroSection(context, userData, l10n),

                            // Daily goal card (overlapping hero)
                            _buildDailyGoalCard(context, userData, l10n),

                            // Main content area
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // "Start Learning" button
                                  _buildStartLearningButton(
                                    context,
                                    l10n,
                                    categoriesAsync,
                                  ),

                                  const SizedBox(height: 24),

                                  // Categories section
                                  categoriesAsync.when(
                                    data: (categories) =>
                                        _buildCategoriesSection(
                                          context,
                                          categories,
                                          l10n,
                                        ),
                                    loading: () => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    error: (error, stack) => Center(
                                      child: Text('${l10n.error}: $error'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
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
                    Text('${l10n.error}: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Refresh by invalidating the provider
                        if (userId != null) {
                          ref.invalidate(userDataProvider(userId));
                        }
                      },
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Build top bar with level/streak and XP
  /// Requirements: 2.1
  Widget _buildTopBar(
    BuildContext context,
    dynamic userData,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Level and streak
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
              const SizedBox(width: 4),
              Text(
                '${userData.currentLevel}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.local_fire_department,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 4),
              Text(
                '${userData.streakCurrent}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          // XP and profile
          Row(
            children: [
              Text(
                '${userData.totalXp} XP',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.teal.shade100,
                child: Icon(
                  Icons.person,
                  size: 20,
                  color: Colors.teal.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build hero section with dashboard image and greeting
  /// Requirements: 2.7
  Widget _buildHeroSection(
    BuildContext context,
    dynamic userData,
    AppLocalizations l10n,
  ) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/app_images/dashboard.png'),
          fit: BoxFit.cover,
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.teal.shade600, Colors.teal.shade400],
        ),
      ),
      child: Stack(
        children: [
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
          // Text content
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hallo, ${userData.displayName}!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bereit für die nächste Lektion?',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.teal.shade100),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build daily goal card (overlapping hero section)
  /// Requirements: 2.1
  Widget _buildDailyGoalCard(
    BuildContext context,
    dynamic userData,
    AppLocalizations l10n,
  ) {
    // Calculate daily progress (example: 20/50 XP)
    final dailyGoal = 50;
    final dailyProgress = userData.weeklyXpCurrent % dailyGoal;
    final progressPercentage = dailyProgress / dailyGoal;

    return Transform.translate(
      offset: const Offset(0, -24),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TAGESZIEL',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$dailyProgress / $dailyGoal XP',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 100,
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: progressPercentage,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.yellow.shade600,
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build "Start Learning" button
  /// Requirements: 2.6
  Widget _buildStartLearningButton(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<List<dynamic>> categoriesAsync,
  ) {
    return ElevatedButton(
      onPressed: categoriesAsync.hasValue && categoriesAsync.value!.isNotEmpty
          ? () {
              // Pick a random category for the quiz
              final categories = categoriesAsync.value!;
              final randomCategory =
                  categories[Random().nextInt(categories.length)];

              // Navigate to quiz length screen with random category
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const QuizLengthScreen(),
                  settings: RouteSettings(arguments: randomCategory),
                ),
              );
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal.shade500,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.play_circle, size: 28),
          const SizedBox(width: 8),
          Text(
            'Jetzt Lernen',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Build categories section with grid
  /// Requirements: 2.2, 2.3, 2.4, 2.5
  Widget _buildCategoriesSection(
    BuildContext context,
    List<dynamic> categories,
    AppLocalizations l10n,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final userId = ref.watch(currentUserIdProvider);
        final userDataAsync = userId != null
            ? ref.watch(userDataProvider(userId))
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kategorien',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Display categories in a column (one per row)
            ...categories.map((category) {
              final progress = userDataAsync?.value?.getCategoryProgress(
                category.id,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 1.0),
                child: CategoryCard(category: category, progress: progress),
              );
            }),
          ],
        );
      },
    );
  }
}
