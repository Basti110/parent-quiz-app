import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/question.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';

/// QuizExplanationScreen shows the explanation after answering a question
class QuizExplanationScreen extends StatelessWidget {
  const QuizExplanationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final question = args['question'] as Question;
    final isCorrect = args['isCorrect'] as bool;
    final isLastQuestion = args['isLastQuestion'] as bool;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isCorrect
            ? AppColors.successLight
            : AppColors.errorLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textSecondary),
          onPressed: () => _showExitConfirmation(context),
        ),
        title: Text(
          isCorrect ? l10n.correct : l10n.incorrect,
          style: TextStyle(
            color: isCorrect ? AppColors.success : AppColors.error,
            fontWeight: FontWeight.w600,
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
                  // Question card
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: MarkdownBody(
                      data: question.text,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                          color:
                              Theme.of(context).textTheme.bodyLarge?.color ??
                              AppColors.textPrimary,
                          height: 1.4,
                        ),
                        strong: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).textTheme.bodyLarge?.color ??
                              AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Explanation section
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: MarkdownBody(
                      data: question.explanation,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          fontSize: 16,
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color ??
                              AppColors.iconPrimary,
                          height: 1.5,
                        ),
                        strong: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color ??
                              AppColors.iconPrimary,
                        ),
                      ),
                    ),
                  ),

                  // Tips section (if available)
                  if (question.tips != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.crown, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.crown,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.lightbulb,
                                  color: AppColors.textOnPrimary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'ELTERN-TIPP',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warning,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          MarkdownBody(
                            data: question.tips!,
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(
                                fontSize: 16,
                                color: AppColors.warning,
                                height: 1.5,
                              ),
                              strong: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Source link (if available)
                  if (question.sourceUrl != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.info, width: 1),
                      ),
                      child: InkWell(
                        onTap: () => _launchUrl(context, question.sourceUrl!),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.info,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.science,
                                color: AppColors.textOnPrimary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Wissenschaftliche Quelle',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.info,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    question.sourceLabel ?? l10n.viewSource,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.info,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.open_in_new,
                              color: AppColors.info,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom button
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isLastQuestion ? l10n.finishQuiz.toUpperCase() : 'WEITER',
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
            child: Text(l10n.no),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );

    if (shouldExit == true && context.mounted) {
      // Pop back to home, skipping the quiz screen
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.couldNotOpenLink)));
      }
    }
  }
}
