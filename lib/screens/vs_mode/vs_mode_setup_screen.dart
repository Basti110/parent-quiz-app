import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/category.dart';
import '../../providers/auth_providers.dart';
import '../../providers/quiz_providers.dart';

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
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    final playerAName = _playerAController.text.trim();
    final playerBName = _playerBController.text.trim();

    if (playerAName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Player A name')),
      );
      return;
    }

    if (playerBName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Player B name')),
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
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('VS Mode Setup')),
      body: categoriesAsync.when(
        data: (categories) => SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Pass & Play Duel',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Compete with a friend on the same device',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Category selection
              Text(
                'Select Category',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...categories.map((category) => _buildCategoryCard(category)),
              const SizedBox(height: 24),

              // Quiz length selection
              Text(
                'Questions per Player',
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
                'Player Names',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _playerAController,
                decoration: const InputDecoration(
                  labelText: 'Player A',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _playerBController,
                decoration: const InputDecoration(
                  labelText: 'Player B',
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
                child: const Text('Start Duel', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading categories: $error')),
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    final isSelected = _selectedCategory?.id == category.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? Colors.blue.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
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
                const Icon(Icons.check_circle, color: Colors.blue)
              else
                const Icon(Icons.radio_button_unchecked, color: Colors.grey),
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

    return Card(
      color: isSelected ? Colors.blue.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
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
                  color: isSelected ? Colors.blue : null,
                ),
              ),
              const SizedBox(height: 4),
              Text('questions', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
