import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/category_progress.dart';
import '../screens/quiz/quiz_length_screen.dart';

/// CategoryCard displays a quiz category with its icon, title, and progress bar.
/// Implements icon fallback to default.png when category-specific icon is missing.
/// Requirements: 2.3, 2.4
class CategoryCard extends StatelessWidget {
  final Category category;
  final CategoryProgress? progress;

  const CategoryCard({super.key, required this.category, this.progress});

  @override
  Widget build(BuildContext context) {
    // Construct icon path with fallback to default.png
    final iconPath = 'assets/app_images/categories/${category.iconName}.png';
    const defaultIconPath = 'assets/app_images/categories/default.png';

    // Calculate progress percentage
    final questionsAnswered = progress?.questionsAnswered ?? 0;
    final totalQuestions = category.totalQuestions;
    final progressPercentage = totalQuestions > 0
        ? questionsAnswered / totalQuestions
        : 0.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 2),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to QuizLengthScreen with category as argument
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const QuizLengthScreen(),
              settings: RouteSettings(arguments: category),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Category icon with colored background
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getCategoryColor(
                    category.iconName,
                  ).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    iconPath,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to default icon if category icon is missing
                      return Image.asset(
                        defaultIconPath,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // If even default icon is missing, show icon placeholder
                          return Center(
                            child: Icon(
                              Icons.category,
                              size: 40,
                              color: _getCategoryColor(category.iconName),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Title and progress bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Category title
                    Text(
                      category.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressPercentage,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getCategoryColor(category.iconName),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Chevron icon
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Get color based on category icon name
  Color _getCategoryColor(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'sleep':
        return Colors.indigo;
      case 'nutrition':
        return Colors.orange;
      case 'health':
        return Colors.green;
      case 'play':
        return Colors.blue;
      default:
        return Colors.teal;
    }
  }
}
