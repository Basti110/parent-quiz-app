import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../theme/app_colors.dart';

/// QuizLengthScreen allows user to select session size (5 or 10 questions)
/// Requirements: 3.4
class QuizLengthScreen extends StatelessWidget {
  const QuizLengthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get category from navigation arguments (null means cross-category mode)
    final category = ModalRoute.of(context)!.settings.arguments as Category?;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isAllCategories = category == null;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Quiz-Länge wählen',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Category title or "All Categories"
              Text(
                isAllCategories ? 'Alle Kategorien' : category!.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isAllCategories 
                    ? 'Intelligente Fragenauswahl aus allen Kategorien\nWie viele Fragen möchtest du beantworten?'
                    : 'Wie viele Fragen möchtest du beantworten?',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDarkMode
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // 5 questions option
              _buildLengthOption(
                context,
                questionCount: 5,
                xpBonus: 10,
                category: category,
                icon: Icons.flash_on,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16),

              // 10 questions option
              _buildLengthOption(
                context,
                questionCount: 10,
                xpBonus: 25,
                category: category,
                icon: Icons.emoji_events,
                isDarkMode: isDarkMode,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLengthOption(
    BuildContext context, {
    required int questionCount,
    required int xpBonus,
    required Category? category,
    required IconData icon,
    required bool isDarkMode,
  }) {
    final borderColor = isDarkMode
        ? AppColors.textSecondary.withValues(alpha: 0.2)
        : AppColors.border;
    final shadowColor = isDarkMode
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.05);
    final iconBgColor = isDarkMode
        ? AppColors.primaryDark.withValues(alpha: 0.2)
        : AppColors.primaryLightest;
    final iconColor = isDarkMode
        ? AppColors.primaryLight
        : AppColors.primaryDark;
    final chevronColor = isDarkMode
        ? AppColors.textSecondaryDark
        : AppColors.iconSecondary;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            '/quiz',
            arguments: {'category': category, 'questionCount': questionCount},
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 32, color: iconColor),
              ),
              const SizedBox(width: 20),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$questionCount Fragen',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+$xpBonus XP Bonus',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.xp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '~${(questionCount * 0.5).toInt()} Minuten',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDarkMode
                            ? AppColors.textSecondaryDark
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              // Chevron
              Icon(Icons.chevron_right, color: chevronColor, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
