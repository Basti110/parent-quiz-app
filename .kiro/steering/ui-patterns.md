---
inclusion: fileMatch
fileMatchPattern: "lib/screens/**/*.dart"
---

# UI Patterns and Guidelines

## Screen Structure

Every screen should follow this basic structure:

```dart
class MyScreen extends ConsumerWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Title'),
        actions: [
          // Optional actions
        ],
      ),
      body: _buildBody(context, ref),
      floatingActionButton: _buildFAB(), // Optional
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    // Main content
  }
}
```

## Loading States

Always handle loading states with AsyncValue:

```dart
final dataAsync = ref.watch(dataProvider);

return dataAsync.when(
  data: (data) => _buildContent(data),
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (error, stack) => Center(
    child: Text('Error: $error'),
  ),
);
```

## Error Display

Use SnackBar for transient errors:

```dart
void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 3),
    ),
  );
}
```

Use AlertDialog for important errors requiring acknowledgment:

```dart
void _showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Error'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
```

## Form Validation

Use Form and TextFormField with validators:

```dart
final _formKey = GlobalKey<FormState>();

Form(
  key: _formKey,
  child: Column(
    children: [
      TextFormField(
        decoration: const InputDecoration(labelText: 'Email'),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter an email';
          }
          if (!value.contains('@')) {
            return 'Please enter a valid email';
          }
          return null;
        },
      ),
      ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // Process form
          }
        },
        child: const Text('Submit'),
      ),
    ],
  ),
)
```

## Navigation

Use named routes for navigation:

```dart
// Navigate to screen
Navigator.pushNamed(context, '/quiz');

// Navigate with arguments
Navigator.pushNamed(
  context,
  '/quiz',
  arguments: {'categoryId': categoryId, 'questionCount': 10},
);

// Replace current screen
Navigator.pushReplacementNamed(context, '/home');

// Pop back
Navigator.pop(context);
```

## Lists

Use ListView.builder for dynamic lists:

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    final item = items[index];
    return ListTile(
      title: Text(item.title),
      subtitle: Text(item.description),
      onTap: () => _handleItemTap(item),
    );
  },
)
```

## Buttons

Standard button patterns:

```dart
// Primary action
ElevatedButton(
  onPressed: isLoading ? null : _handleSubmit,
  child: isLoading
    ? const CircularProgressIndicator()
    : const Text('Submit'),
)

// Secondary action
TextButton(
  onPressed: _handleCancel,
  child: const Text('Cancel'),
)

// Icon button
IconButton(
  icon: const Icon(Icons.settings),
  onPressed: _openSettings,
)
```

## Dialogs

Confirmation dialog pattern:

```dart
Future<bool> _showConfirmDialog(BuildContext context, String message) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirm'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  ) ?? false;
}
```

## Spacing and Layout

Use consistent spacing:

```dart
// Vertical spacing
const SizedBox(height: 16),

// Horizontal spacing
const SizedBox(width: 16),

// Padding
const EdgeInsets.all(16),
const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

// Safe area
SafeArea(
  child: child,
)
```

## Responsive Design

Check screen size when needed:

```dart
final screenWidth = MediaQuery.of(context).size.width;
final isTablet = screenWidth > 600;

// Adjust layout based on screen size
if (isTablet) {
  return _buildTabletLayout();
} else {
  return _buildPhoneLayout();
}
```

## Theme Access

Access theme colors and text styles:

```dart
final theme = Theme.of(context);
final textTheme = theme.textTheme;
final colorScheme = theme.colorScheme;

Text(
  'Title',
  style: textTheme.headlineMedium,
)

Container(
  color: colorScheme.primary,
)
```
