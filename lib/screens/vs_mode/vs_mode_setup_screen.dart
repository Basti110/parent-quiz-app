import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/category.dart';
import '../../providers/auth_providers.dart';
import '../../providers/quiz_providers.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// VSModeSetupScreen allows users to configure a pass-and-play duel
/// Requirements: 9.1, 9.2
class VSModeSetupScreen extends ConsumerStatefulWidget {
  const VSModeSetupScreen({super.key});

  @override
  ConsumerState<VSModeSetupScreen> createState() => _VSModeSetupScreenState();
}

class _VSModeSetupScreenState extends ConsumerState<VSModeSetupScreen> {
  Category? _selectedCategory;
  int _questionsPerPlayer = 5;
  final TextEditingController _playerAController = TextEditingController();
  final TextEditingController _playerBController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set default player A name to current user's name
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        final userService = ref.read(userServiceProvider);
        userService
            .getUserData(userId)
            .then((userData) {
              if (mounted) {
                setState(() {
                  _playerAController.text = userData.displayName;
                });
              }
            })
            .catchError((e) {
              // If we can't get user data, leave it empty
            });
      }
    });
  }

  @override
  void dispose() {
    _playerAController.dispose();
    _playerBController.dispose();
    super.dispose();
  }

  void _startVSMode() {
    final l10n = AppLocalizations.of(context)!;
    
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectCategory)));
      return;
    }

    final playerAName = _playerAController.text.trim();
    final playerBName = _playerBController.text.trim();

    if (playerAName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterPlayerAName)),
      );
      return;
    }

    if (playerBName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterPlayerBName)),
      );
      return;
    }

    // Navigate to VS Mode quiz screen
    Navigator.of(context).pushNamed(
      '/vs-mode-quiz',
      arguments: {
        'category': _selectedCategory!,
        'questionsPerPlayer': _questionsPerPlayer,
        'playerAName': playerAName,
        'playerBName': playerBName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.vsModeSetup)),
      body: categoriesAsync.when(
        data: (categories) => SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                AppLocalizations.of(context)!.passAndPlayDuel,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.competeWithFriendSameDevice,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Category selection
              Text(
                AppLocalizations.of(context)!.selectCategory,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...categories.map((category) => _buildCategoryCard(category)),
              const SizedBox(height: 24),

              // Quiz length selection
              Text(
                AppLocalizations.of(context)!.questionsPerPlayer,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildQuizLengthOption(5)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildQuizLengthOption(10)),
                ],
              ),
              const SizedBox(height: 24),

              // Player names
              Text(
                AppLocalizations.of(context)!.playerNames,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _playerAController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.playerALabel,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _playerBController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.playerBLabel,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 32),

              // Start button
              ElevatedButton(
                onPressed: _startVSMode,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(AppLocalizations.of(context)!.startDuel, style: const TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.loadingCategories),
            ],
          ),
        ),
        error: (error, stack) {
          final l10n = AppLocalizations.of(context)!;
          return Center(child: Text(l10n.errorLoadingCategories(error.toString())));
        },
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    final isSelected = _selectedCategory?.id == category.id;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected
          ? (isDark ? AppColors.primaryDarker : AppColors.primaryLightest)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.border.withOpacity(0.3) : AppColors.border),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategory = category;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              if (isSelected)
                const Icon(Icons.check_circle, color: AppColors.primary)
              else
                Icon(
                  Icons.radio_button_unchecked,
                  color: theme.iconTheme.color,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizLengthOption(int count) {
    final isSelected = _questionsPerPlayer == count;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: isSelected
          ? (isDark ? AppColors.primaryDarker : AppColors.primaryLightest)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.border.withOpacity(0.3) : AppColors.border),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _questionsPerPlayer = count;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                '$count',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(AppLocalizations.of(context)!.questionsLowercase, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
