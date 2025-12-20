import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../providers/quiz_providers.dart';
import '../../widgets/category_card.dart';
import '../../widgets/app_header.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../quiz/quiz_length_screen.dart';

/// HomeScreen (Dashboard) with header, hero image, daily goal, categories, and action button
/// Requirements: 2.1, 2.2, 2.5, 2.6, 2.7, 5.1, 5.2, 5.3, 5.4
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _celebrationController;
  late Animation<double> _scaleAnimation;
  bool _hasShownCelebration = false;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  void _checkAndShowCelebration(bool isGoalMet) {
    if (isGoalMet && !_hasShownCelebration) {
      _hasShownCelebration = true;
      _celebrationController.forward();
    } else if (!isGoalMet) {
      _hasShownCelebration = false;
      _celebrationController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
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
              data: (userData) {
                // Check if goal is met and trigger celebration
                final isGoalMet = userData.questionsAnsweredToday >= userData.dailyGoal;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _checkAndShowCelebration(isGoalMet);
                });

                return Column(
                  children: [
                    // Top bar with level/streak and XP
                    const AppHeader(),

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
                );
              },
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



  /// Build hero section with dashboard image and greeting
  /// Requirements: 2.7
  Widget _buildHeroSection(
    BuildContext context,
    dynamic userData,
    AppLocalizations l10n,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          colors: [
            isDark ? AppColors.backgroundDark : AppColors.primaryDark,
            isDark ? AppColors.surfaceDark : AppColors.primary,
          ],
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
                  Colors.black.withValues(alpha: isDark ? 0.3 : 0.0),
                  Colors.black.withValues(alpha: isDark ? 0.7 : 0.6),
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.9)
                        : AppColors.primaryLightest,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build daily goal card (overlapping hero section)
  /// Requirements: 5.1, 5.2, 5.3, 5.4
  Widget _buildDailyGoalCard(
    BuildContext context,
    dynamic userData,
    AppLocalizations l10n,
  ) {
    // Get daily progress from user data
    final dailyGoal = userData.dailyGoal;
    final questionsAnswered = userData.questionsAnsweredToday;
    final progressPercentage = questionsAnswered / dailyGoal;
    final isGoalMet = questionsAnswered >= dailyGoal;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Transform.translate(
      offset: const Offset(0, -24),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ??
              (isDark ? AppColors.surfaceDark : AppColors.surface),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
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
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$questionsAnswered / $dailyGoal Fragen',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      if (isGoalMet) ...[
                        const SizedBox(width: 8),
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 24,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 100,
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: progressPercentage.clamp(0.0, 1.0),
                    backgroundColor: isDark
                        ? AppColors.textSecondary.withValues(alpha: 0.3)
                        : AppColors.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isGoalMet ? AppColors.success : AppColors.warning,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ElevatedButton(
      onPressed: categoriesAsync.hasValue && categoriesAsync.value!.isNotEmpty
          ? () {
              // Navigate to quiz length screen with special "all categories" mode
              // Pass null as category to indicate cross-category selection
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const QuizLengthScreen(),
                  settings: const RouteSettings(arguments: null), // null = all categories
                ),
              );
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? AppColors.primaryDark : AppColors.primary,
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

        // Filter out premium categories
        final nonPremiumCategories = categories
            .where((category) => category.isPremium != true)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kategorien',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            // Display non-premium categories in a column (one per row)
            ...nonPremiumCategories.map((category) {
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
