import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../models/feedback.dart';
import '../../providers/auth_providers.dart';
import '../../providers/feedback_providers.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';

/// Comprehensive feedback form screen accessible from settings
/// Collects detailed ratings and feedback from users
class FeedbackFormScreen extends ConsumerStatefulWidget {
  const FeedbackFormScreen({super.key});

  @override
  ConsumerState<FeedbackFormScreen> createState() => _FeedbackFormScreenState();
}

class _FeedbackFormScreenState extends ConsumerState<FeedbackFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCommentController = TextEditingController();
  final _doBetterController = TextEditingController();
  final _futureFeaturesController = TextEditingController();

  bool _isSubmitting = false;

  // Rating values (1-10 scale)
  double _ratingApp = 5.0;
  double _ratingTheme = 5.0;
  double _ratingDuelMode = 5.0;
  double _learningFactor = 5.0;
  double _scientificTrust = 5.0;

  @override
  void dispose() {
    _userCommentController.dispose();
    _doBetterController.dispose();
    _futureFeaturesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.feedback),
        backgroundColor: theme.cardColor,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Introduction
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.feedback,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.yourFeedbackMatters,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.feedbackDescription,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Overall Experience Section
            _buildSectionCard(
              context,
              l10n.overallExperience,
              [
                _buildRatingSlider(
                  l10n.appRating,
                  l10n.appRatingDescription,
                  _ratingApp,
                  (value) => setState(() => _ratingApp = value),
                ),
                const SizedBox(height: 16),
                _buildRatingSlider(
                  l10n.themeRating,
                  l10n.themeRatingDescription,
                  _ratingTheme,
                  (value) => setState(() => _ratingTheme = value),
                ),
                const SizedBox(height: 16),
                _buildRatingSlider(
                  l10n.duelModeRating,
                  l10n.duelModeRatingDescription,
                  _ratingDuelMode,
                  (value) => setState(() => _ratingDuelMode = value),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Learning & Trust Section
            _buildSectionCard(
              context,
              l10n.learningAndTrust,
              [
                _buildRatingSlider(
                  l10n.learningFactor,
                  l10n.learningFactorDescription,
                  _learningFactor,
                  (value) => setState(() => _learningFactor = value),
                ),
                const SizedBox(height: 16),
                _buildRatingSlider(
                  l10n.scientificTrust,
                  l10n.scientificTrustDescription,
                  _scientificTrust,
                  (value) => setState(() => _scientificTrust = value),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Comments Section
            _buildSectionCard(
              context,
              l10n.additionalFeedback,
              [
                // General comment (required)
                Text(
                  l10n.generalComment,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _userCommentController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: l10n.shareYourThoughts + ' (${l10n.optional})',
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

                const SizedBox(height: 20),

                // What can we do better?
                Text(
                  l10n.whatCanWeDoBetter,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _doBetterController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: l10n.suggestImprovements,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),

                const SizedBox(height: 20),

                // Future features
                Text(
                  l10n.futureFeatures,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _futureFeaturesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: l10n.suggestFeatures,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Privacy note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.privacy_tip_outlined,
                    size: 16,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.feedbackPrivacyNote,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.surfaceDark : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.backgroundDark : AppColors.textPrimary)
                .withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRatingSlider(
    String title,
    String description,
    double value,
    ValueChanged<double> onChanged,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.round()}/10',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value,
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: onChanged,
          ),
        ),
        // Scale labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1',
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
              ),
            ),
            Text(
              '10',
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      _showError(AppLocalizations.of(context)!.pleaseSignIn);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final feedbackService = ref.read(feedbackServiceProvider);
      final userService = UserService();
      final userData = await userService.getUserData(currentUserId);
      final appContext = feedbackService.createAppContext();

      final feedback = CommonFeedback(
        createdAt: DateTime.now(),
        userComment: _userCommentController.text.trim().isEmpty 
            ? 'General feedback submitted'
            : _userCommentController.text.trim(),
        userId: currentUserId,
        username: userData.displayName,
        status: 'open',
        appContext: appContext,
        ratingApp: _ratingApp.round(),
        ratingTheme: _ratingTheme.round(),
        ratingDuelMode: _ratingDuelMode.round(),
        learningFactor: _learningFactor.round(),
        scientificTrust: _scientificTrust.round(),
        doBetter: _doBetterController.text.trim(),
        futureFeatures: _futureFeaturesController.text.trim(),
      );

      await feedbackService.submitCommonFeedback(feedback);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.feedbackSubmittedThankYou),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );

        // Navigate back to settings
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showError('${AppLocalizations.of(context)!.error}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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