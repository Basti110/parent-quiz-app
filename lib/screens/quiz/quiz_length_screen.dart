import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../theme/app_colors.dart';

/// QuizLengthScreen allows user to select session size (5 or 10 questions)
/// Requirements: 3.4
class QuizLengthScreen extends StatelessWidget {
  const QuizLengthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get category from navigation arguments
    final category = ModalRoute.of(context)!.settings.arguments as Category;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
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
              // Category title
              Text(
                category.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Wie viele Fragen möchtest du beantworten?',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
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
              ),
              const SizedBox(height: 16),

              // 10 questions option
              _buildLengthOption(
                context,
                questionCount: 10,
                xpBonus: 25,
                category: category,
                icon: Icons.emoji_events,
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
    required Category category,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                  color: AppColors.primaryLightest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 32, color: AppColors.primaryDark),
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
                        color: AppColors.textPrimary,
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
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              // Chevron
              Icon(
                Icons.chevron_right,
                color: AppColors.iconSecondary,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
