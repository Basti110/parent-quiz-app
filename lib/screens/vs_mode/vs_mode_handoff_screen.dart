import 'package:flutter/material.dart';
import '../../models/vs_mode_session.dart';
import '../../models/question.dart';

/// VSModeHandoffScreen displays a transition screen between players
/// Requirements: 9.4
class VSModeHandoffScreen extends StatelessWidget {
  const VSModeHandoffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final session = args['session'] as VSModeSession;
    final questionsMap = args['questionsMap'] as Map<String, Question>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('VS Mode'),
        automaticallyImplyLeading: false, // Prevent back navigation
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Player A completed icon
              Icon(Icons.check_circle, size: 80, color: Colors.blue.shade400),
              const SizedBox(height: 24),

              // Player A finished message
              Text(
                '${session.playerAName} finished!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Player A score
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Score: ${session.playerAScore}/${session.questionsPerPlayer}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Handoff message
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200, width: 2),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.swap_horiz,
                      size: 48,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pass device to',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      session.playerBName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Continue button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed(
                    '/vs-mode-quiz',
                    arguments: {
                      'session': session,
                      'questionsMap': questionsMap,
                      'currentPlayer': 'playerB',
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Continue', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
