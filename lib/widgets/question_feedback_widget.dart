import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/feedback.dart';
import '../models/question.dart';
import '../providers/auth_providers.dart';
import '../providers/feedback_providers.dart';
import '../theme/app_colors.dart';

/// Quick feedback widget for reporting issues with questions
/// Shows as a hint box that can be expanded to report problems
class QuestionFeedbackWidget extends ConsumerStatefulWidget {
  final Question question;
  final String categoryName;

  const QuestionFeedbackWidget({
    super.key,
    required this.question,
    required this.categoryName,
  });

  @override
  ConsumerState<QuestionFeedbackWidget> createState() => _QuestionFeedbackWidgetState();
}

class _QuestionFeedbackWidgetState extends ConsumerState<QuestionFeedbackWidget> {
  bool _isExpanded = false;
  bool _isSubmitting = false;
  QuestionIssueType _selectedIssueType = QuestionIssueType.other;
  final _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          // Header - always visible
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
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.reportIssue,
                      style: TextStyle(
                        fontSize: 14,
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

          // Expanded form
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
                    // Issue type selection
                    Text(
                      l10n.issueType,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: QuestionIssueType.values.map((type) {
                        final isSelected = _selectedIssueType == type;
                        return FilterChip(
                          label: Text(_getIssueTypeLabel(l10n, type)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedIssueType = type);
                            }
                          },
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primary : null,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Comment field
                    Text(
                      l10n.additionalComments,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: '${l10n.describeIssue} (${l10n.optional})',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      validator: (value) {
                        // Make comment optional - only validate if user entered something
                        if (value != null && value.trim().isNotEmpty && value.trim().length < 10) {
                          return l10n.commentTooShort;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitFeedback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.textOnPrimary,
                                  ),
                                ),
                              )
                            : Text(
                                l10n.submitFeedback,
                                style: const TextStyle(
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

  String _getIssueTypeLabel(AppLocalizations l10n, QuestionIssueType type) {
    switch (type) {
      case QuestionIssueType.typo:
        return l10n.typo;
      case QuestionIssueType.contentOutdated:
        return l10n.contentOutdated;
      case QuestionIssueType.brokenLink:
        return l10n.brokenLink;
      case QuestionIssueType.other:
        return l10n.other;
    }
  }

  Future<void> _submitFeedback() async {
    debugPrint('=== Question Feedback Submission Started ===');
    
    if (!_formKey.currentState!.validate()) {
      debugPrint('Form validation failed');
      return;
    }

    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      debugPrint('User not authenticated');
      if (mounted) {
        _showError(AppLocalizations.of(context)!.pleaseSignIn);
      }
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    debugPrint('Setting loading state to true');
    setState(() => _isSubmitting = true);

    try {
      debugPrint('Getting user data...');
      final userService = ref.read(userServiceProvider);
      final currentUser = await userService.getUserData(currentUserId);
      
      debugPrint('Getting feedback service...');
      final feedbackService = ref.read(feedbackServiceProvider);
      
      debugPrint('Creating app context...');
      final appContext = feedbackService.createAppContext();

      debugPrint('Creating feedback object...');
      final feedback = QuestionFeedback(
        createdAt: DateTime.now(),
        userComment: _commentController.text.trim().isEmpty 
            ? 'Issue reported: ${_getIssueTypeLabel(l10n, _selectedIssueType)}'
            : _commentController.text.trim(),
        userId: currentUserId,
        username: currentUser.displayName,
        status: 'open',
        appContext: appContext,
        questionId: widget.question.id,
        category: widget.categoryName,
        issueType: _selectedIssueType.value,
        questionSnapshot: QuestionSnapshot(
          text: widget.question.text,
          options: widget.question.options,
          correctIndices: widget.question.correctIndices,
          explanation: widget.question.explanation,
          tips: widget.question.tips,
          sourceLabel: widget.question.sourceLabel,
          sourceUrl: widget.question.sourceUrl,
          difficulty: widget.question.difficulty,
          categoryTitle: widget.categoryName,
        ),
      );

      debugPrint('Submitting feedback...');
      await feedbackService.submitQuestionFeedback(feedback);
      debugPrint('Feedback submitted successfully!');

      if (mounted) {
        debugPrint('Showing success message...');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.feedbackSubmitted),
            backgroundColor: AppColors.success,
          ),
        );

        debugPrint('Resetting form...');
        _commentController.clear();
        setState(() {
          _isExpanded = false;
          _selectedIssueType = QuestionIssueType.other;
        });
      }
    } catch (e) {
      debugPrint('Error during submission: $e');
      if (mounted) {
        _showError('${l10n.error}: $e');
      }
    } finally {
      debugPrint('Setting loading state to false');
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
    
    debugPrint('=== Question Feedback Submission Completed ===');
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