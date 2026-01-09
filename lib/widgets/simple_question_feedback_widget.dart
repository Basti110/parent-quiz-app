import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/feedback.dart';
import '../models/question.dart';
import '../providers/auth_providers.dart';
import '../providers/feedback_providers.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';

/// Einfaches Feedback-Widget für Fragen - nur "Fehler melden" mit Textfeld
class SimpleQuestionFeedbackWidget extends ConsumerStatefulWidget {
  final Question question;
  final String categoryName;

  const SimpleQuestionFeedbackWidget({
    super.key,
    required this.question,
    required this.categoryName,
  });

  @override
  ConsumerState<SimpleQuestionFeedbackWidget> createState() => _SimpleQuestionFeedbackWidgetState();
}

class _SimpleQuestionFeedbackWidgetState extends ConsumerState<SimpleQuestionFeedbackWidget> {
  bool _isExpanded = false;
  bool _isSubmitting = false;
  final _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.surfaceDark : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.backgroundDark : AppColors.textPrimary)
                .withValues(alpha: isDark ? 0.1 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header - immer sichtbar
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.feedback_outlined,
                    size: 20,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Feedback geben',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),

          // Erweiterte Form
          if (_isExpanded) ...[
            Divider(
              height: 1,
              color: isDark ? AppColors.surfaceDark : AppColors.borderLight,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Beschreibung
                    Text(
                      'Beschreibe das Problem mit dieser Frage:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Textfeld
                    TextFormField(
                      controller: _commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'z.B. Tippfehler, veraltete Information, unklare Formulierung... (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      validator: (value) {
                        // Optional - nur validieren wenn Text eingegeben wurde
                        if (value != null && value.trim().isNotEmpty && value.trim().length < 5) {
                          return 'Beschreibung zu kurz (mindestens 5 Zeichen)';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitFeedback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.info,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Feedback senden',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submitFeedback() async {
    print('=== Einfaches Fragen-Feedback gestartet ===');
    
    if (!_formKey.currentState!.validate()) {
      print('Formular-Validierung fehlgeschlagen');
      return;
    }

    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      print('Benutzer nicht authentifiziert');
      _showError('Bitte melde dich an, um Feedback zu senden');
      return;
    }

    print('Setze Loading-Status auf true');
    setState(() => _isSubmitting = true);

    try {
      print('Hole Feedback-Service...');
      final feedbackService = ref.read(feedbackServiceProvider);
      
      print('Hole Benutzer-Service für Username...');
      final userService = UserService();
      final userData = await userService.getUserData(currentUserId);
      
      print('Erstelle App-Kontext...');
      final appContext = feedbackService.createAppContext();

      print('Erstelle Question-Snapshot...');
      final questionSnapshot = QuestionSnapshot(
        text: widget.question.text,
        options: widget.question.options,
        correctIndices: widget.question.correctIndices,
        explanation: widget.question.explanation,
        tips: widget.question.tips,
        sourceLabel: widget.question.sourceLabel,
        sourceUrl: widget.question.sourceUrl,
        difficulty: widget.question.difficulty,
        categoryTitle: widget.categoryName,
      );

      print('Erstelle Feedback-Objekt...');
      final feedback = QuestionFeedback(
        createdAt: DateTime.now(),
        userComment: _commentController.text.trim().isEmpty 
            ? 'Feedback zu Frage gegeben (keine Details angegeben)'
            : _commentController.text.trim(),
        userId: currentUserId,
        username: userData.displayName,
        status: 'open',
        appContext: appContext,
        questionId: widget.question.id,
        category: widget.categoryName,
        issueType: 'other', // Genereller Fehler
        questionSnapshot: questionSnapshot,
      );

      print('Sende Feedback...');
      await feedbackService.submitQuestionFeedback(feedback);
      print('Feedback erfolgreich gesendet!');

      if (mounted) {
        print('Zeige Erfolgsmeldung...');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback gesendet! Vielen Dank für dein Feedback.'),
            backgroundColor: AppColors.success,
          ),
        );

        print('Setze Formular zurück...');
        _commentController.clear();
        setState(() {
          _isExpanded = false;
        });
      }
    } catch (e) {
      print('Fehler beim Senden: $e');
      if (mounted) {
        _showError('Fehler beim Senden: $e');
      }
    } finally {
      print('Setze Loading-Status auf false');
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
    
    print('=== Einfaches Fragen-Feedback beendet ===');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}