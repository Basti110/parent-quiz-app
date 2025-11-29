import 'package:flutter/material.dart';
import '../../models/category.dart';

/// QuizLengthScreen allows user to select session size (5 or 10 questions)
/// Requirements: 3.4
class QuizLengthScreen extends StatelessWidget {
  const QuizLengthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get category from navigation arguments
    final category = ModalRoute.of(context)!.settings.arguments as Category;

    return Scaffold(
      appBar: AppBar(title: const Text('Select Quiz Length')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Text(
              'How many questions?',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              category.title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // 5 questions option
            _buildLengthOption(
              context,
              questionCount: 5,
              xpBonus: 10,
              category: category,
            ),
            const SizedBox(height: 16),

            // 10 questions option
            _buildLengthOption(
              context,
              questionCount: 10,
              xpBonus: 25,
              category: category,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildLengthOption(
    BuildContext context, {
    required int questionCount,
    required int xpBonus,
    required Category category,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            '/quiz',
            arguments: {'category': category, 'questionCount': questionCount},
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text(
                '$questionCount Questions',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '+$xpBonus XP Bonus',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Estimated time: ${questionCount * 30} seconds',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
