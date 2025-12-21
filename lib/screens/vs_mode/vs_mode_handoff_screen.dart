import 'package:flutter/material.dart';
import '../../models/vs_mode_session.dart';
import '../../models/question.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

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
      body: Column(
        children: [
          // Gradient bar at top
          Container(
            height: 8,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF00897B),
                  Color(0xFF26C6DA),
                  Color(0xFF42A5F5),
                  Color(0xFF5C6BC0),
                  Color(0xFF7E57C2),
                ],
              ),
            ),
          ),

          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // VS Mode display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Player A (completed - highlighted)
                        _buildPlayerAvatar(
                          context: context,
                          playerName: session.playerAName,
                          score: session.playerAScore,
                          isActive: true,
                          isCompleted: true,
                        ),

                        // VS text
                        Text(
                          AppLocalizations.of(context)!.vsText,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade300,
                            letterSpacing: 2,
                          ),
                        ),

                        // Player B (waiting - grayed out)
                        _buildPlayerAvatar(
                          context: context,
                          playerName: session.playerBName,
                          score: 0,
                          isActive: false,
                          isCompleted: false,
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Pass device message
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.swap_horiz,
                            size: 40,
                            color: AppColors.success,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(context)!.passDeviceTo(session.playerBName),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
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
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          backgroundColor: const Color(0xFF5C9EFF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.startPlayerTurn(session.playerBName.toUpperCase()),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerAvatar({
    required BuildContext context,
    required String playerName,
    required int score,
    required bool isActive,
    required bool isCompleted,
  }) {
    final theme = Theme.of(context);
    final borderColor = isActive 
        ? const Color(0xFF00897B) 
        : Colors.grey.shade300;
    final avatarOpacity = isActive ? 1.0 : 0.4;

    return Column(
      children: [
        // Avatar with border
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor,
              width: 4,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey.shade200,
            child: Opacity(
              opacity: avatarOpacity,
              child: Icon(
                Icons.person,
                size: 60,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Player name
        Text(
          isCompleted ? playerName : playerName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isActive ? theme.textTheme.bodyLarge?.color : Colors.grey,
          ),
        ),

        const SizedBox(height: 8),

        // Score display
        Text(
          isCompleted ? AppLocalizations.of(context)!.scoreCorrect(score) : AppLocalizations.of(context)!.scorePlaceholder,
          style: theme.textTheme.titleLarge?.copyWith(
            color: isActive 
                ? const Color(0xFF5C6BC0) 
                : Colors.grey.shade400,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
