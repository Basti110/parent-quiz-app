import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/question.dart';
import '../../l10n/app_localizations.dart';

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
      appBar: AppBar(
        title: Text(isCorrect ? l10n.correct : l10n.incorrect),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Result indicator
            Card(
              color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect ? Colors.green : Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isCorrect ? l10n.correct : l10n.incorrect,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: isCorrect ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Explanation section
            Text(
              l10n.explanation,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  question.explanation,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),

            // Tips section (if available)
            if (question.tips != null) ...[
              const SizedBox(height: 24),
              Text(
                l10n.tips,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          question.tips!,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Source link (if available)
            if (question.sourceUrl != null) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () => _launchUrl(context, question.sourceUrl!),
                icon: const Icon(Icons.open_in_new),
                label: Text(question.sourceLabel ?? l10n.viewSource),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(
            isLastQuestion ? l10n.finishQuiz : l10n.nextQuestion,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
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
