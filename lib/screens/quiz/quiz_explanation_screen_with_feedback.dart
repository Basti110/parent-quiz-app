import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../models/question.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/question_feedback_widget.dart';

/// Example of QuizExplanationScreen with integrated feedback widget
/// This demonstrates how to add the feedback widget to existing quiz screens
class QuizExplanationScreenWithFeedback extends ConsumerWidget {
  const QuizExplanationScreenWithFeedback({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final question = args['question'] as Question;
    final isCorrect = args['isCorrect'] as bool;
    final isLastQuestion = args['isLastQuestion'] as bool;
    final selectedIndices = args['selectedIndices'] as List<int>;
    final categoryName = args['categoryName'] as String? ?? 'Unknown Category';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close,
              color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
              size: 20,
            ),
          ),
          onPressed: () => _showExitConfirmation(context),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isCorrect ? AppColors.success : AppColors.error,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (isCorrect ? AppColors.success : AppColors.error).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? l10n.correct : l10n.incorrect,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question section
                  _buildQuestionSection(context, question, isDarkMode),
                  const SizedBox(height: 16),

                  // Correct answer section
                  _buildCorrectAnswerSection(context, question, isDarkMode),

                  // Wrong answer section (if incorrect)
                  if (!isCorrect) ...[
                    const SizedBox(height: 16),
                    _buildWrongAnswerSection(context, question, selectedIndices, isDarkMode),
                  ],

                  const SizedBox(height: 24),

                  // Explanation section
                  _buildExplanationSection(context, question, isDarkMode),

                  // Tips section (if available)
                  if (question.tips != null && question.tips!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildTipsSection(context, question, isDarkMode),
                  ],

                  // Source section (if available)
                  if (question.sourceLabel != null && question.sourceUrl != null) ...[
                    const SizedBox(height: 16),
                    _buildSourceSection(context, question, isDarkMode),
                  ],

                  const SizedBox(height: 24),

                  // FEEDBACK WIDGET INTEGRATION
                  // This is where the feedback widget is added to allow users to report issues
                  QuestionFeedbackWidget(
                    question: question,
                    categoryName: categoryName,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Continue button
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? AppColors.primaryDark : AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isLastQuestion ? l10n.continue_.toUpperCase() : l10n.continue_.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionSection(BuildContext context, Question question, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode
              ? AppColors.textSecondary.withValues(alpha: 0.2)
              : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUESTION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          MarkdownBody(
            data: question.text,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                fontSize: 17,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                height: 1.5,
              ),
              strong: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectAnswerSection(BuildContext context, Question question, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [
                  AppColors.success.withValues(alpha: 0.2),
                  AppColors.success.withValues(alpha: 0.15),
                ]
              : [AppColors.successLightest, AppColors.teal50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.successLight, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: isDarkMode ? 0.2 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CORRECT ANSWER',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? AppColors.successLight : AppColors.successDark,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                ...question.correctIndices.map((index) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      question.options[index],
                      style: TextStyle(
                        fontSize: 15,
                        color: isDarkMode ? AppColors.successLight : AppColors.successDarkest,
                        height: 1.5,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWrongAnswerSection(
    BuildContext context,
    Question question,
    List<int> selectedIndices,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [
                  AppColors.error.withValues(alpha: 0.2),
                  AppColors.error.withValues(alpha: 0.15),
                ]
              : [AppColors.errorLightest, AppColors.pink50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.errorLight, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: isDarkMode ? 0.2 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cancel, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR ANSWER',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? AppColors.errorLight : AppColors.errorDark,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                ...selectedIndices.map((index) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      question.options[index],
                      style: TextStyle(
                        fontSize: 15,
                        color: isDarkMode ? AppColors.errorLight : AppColors.errorDarkest,
                        height: 1.5,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationSection(BuildContext context, Question question, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode
              ? AppColors.textSecondary.withValues(alpha: 0.2)
              : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.primaryDark : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lightbulb, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'EXPLANATION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? AppColors.primaryLight : AppColors.primary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MarkdownBody(
            data: question.explanation,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                height: 1.6,
              ),
              strong: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection(BuildContext context, Question question, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [
                  AppColors.primaryDark.withValues(alpha: 0.2),
                  AppColors.primaryDark.withValues(alpha: 0.1),
                ]
              : [AppColors.primaryLightest, AppColors.teal50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? AppColors.primaryLight : AppColors.primaryDark,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.primaryLight : AppColors.primaryDark,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.tips_and_updates, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRACTICAL TIP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? AppColors.primaryLight : AppColors.primaryDark,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  question.tips!,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? AppColors.primaryLight : AppColors.primaryDarker,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceSection(BuildContext context, Question question, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16.0),
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
      child: Row(
        children: [
          Icon(
            Icons.link,
            color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              question.sourceLabel!,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _launchUrl(question.sourceUrl!),
            child: Text(
              AppLocalizations.of(context)!.viewSource,
              style: TextStyle(
                color: isDarkMode ? AppColors.primaryLight : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _showExitConfirmation(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.exitQuiz),
        content: Text(l10n.exitQuizConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: Text(l10n.buttonExit),
          ),
        ],
      ),
    );

    if (shouldExit == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}