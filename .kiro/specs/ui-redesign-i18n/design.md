# Design Document

## Overview

This design implements a comprehensive UI redesign and internationalization system for the parent quiz application. The redesign modernizes the user interface with a bottom navigation bar, redesigned dashboard, enhanced VS Mode screen, improved settings, and full multi-language support. The implementation follows Flutter best practices and maintains the existing Riverpod state management architecture.

## Design References

This implementation is based on the following HTML design mockups located in the project root:

- **app_navbar_vs_mode.html**: Provides the visual design for:

  - Bottom navigation bar with icons and labels
  - VS Mode/Friends League screen with leaderboard-style layout
  - Settings screen layout and styling

- **app_dashboard_questions.html**: Provides the visual design for:
  - Dashboard header with crown icon and total correct answers
  - Category cards displayed directly on dashboard
  - Question flow with progress bar
  - Explanation screen with tips display in styled card
  - "Start Random Quiz" button placement

These HTML files serve as the visual reference for styling, spacing, colors, and overall UI patterns.

## Architecture

### Component Structure

```
lib/
├── l10n/                          # Internationalization
│   ├── app_de.arb                # German translations
│   ├── app_en.arb                # English translations
│   └── l10n.yaml                 # L10n configuration
├── models/
│   └── app_settings.dart         # Settings model (theme, language)
├── providers/
│   ├── theme_providers.dart      # Dark mode state
│   └── locale_providers.dart     # Language state
├── screens/
│   ├── main_navigation.dart      # Bottom nav wrapper
│   ├── home/
│   │   └── home_screen.dart      # Redesigned dashboard
│   ├── vs_mode/
│   │   ├── vs_mode_friends_screen.dart  # Friends list
│   │   └── ...                   # Existing VS mode screens
│   ├── settings/
│   │   ├── settings_screen.dart  # Redesigned settings
│   │   └── avatar_selection_screen.dart
│   └── ...
├── widgets/
│   ├── category_card.dart        # Category display widget
│   ├── friend_list_item.dart     # Friend display widget
│   └── avatar_grid.dart          # Avatar selection grid
└── theme/
    ├── app_theme.dart            # Light/dark themes
    └── app_colors.dart           # Color constants
```

### State Management

- **Theme State**: Managed via `themeProvider` (StateNotifierProvider)
- **Locale State**: Managed via `localeProvider` (StateNotifierProvider)
- **Settings Persistence**: Stored in Firestore under user document
- **Navigation State**: Managed by Flutter's Navigator 2.0 with bottom navigation

## Components and Interfaces

### 1. Main Navigation Component

**File**: `lib/screens/main_navigation.dart`

```dart
class MainNavigationScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    VSModeFriendsScreen(),
    LeaderboardScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: AppLocalizations.of(context)!.dashboard,
          ),
          // ... other items
        ],
      ),
    );
  }
}
```

### 2. Internationalization Setup

**File**: `lib/l10n/app_en.arb`

```json
{
  "@@locale": "en",
  "dashboard": "Dashboard",
  "vsMode": "VS Mode",
  "leaderboard": "Leaderboard",
  "settings": "Settings",
  "startRandomQuiz": "Start Random Quiz",
  "correctAnswers": "Correct Answers",
  "darkMode": "Dark Mode",
  "language": "Language",
  "changeAvatar": "Change Avatar",
  "logout": "Logout",
  "addFriend": "Add Friend",
  "friendCode": "Friend Code",
  "wins": "Wins",
  "losses": "Losses",
  "explanation": "Explanation",
  "tips": "Tips",
  "correct": "Correct!",
  "incorrect": "Incorrect",
  "nextQuestion": "Next Question",
  "finishQuiz": "Finish Quiz",
  "checkAnswer": "Check Answer",
  "cancel": "Cancel",
  "add": "Add",
  "save": "Save",
  "noFriends": "No friends yet. Add friends to compete!"
}
```

**File**: `lib/l10n/app_de.arb`

```json
{
  "@@locale": "de",
  "dashboard": "Dashboard",
  "vsMode": "VS Modus",
  "leaderboard": "Bestenliste",
  "settings": "Einstellungen",
  "startRandomQuiz": "Zufälliges Quiz starten",
  "correctAnswers": "Richtige Antworten",
  "darkMode": "Dunkler Modus",
  "language": "Sprache",
  "changeAvatar": "Avatar ändern",
  "logout": "Abmelden",
  "addFriend": "Freund hinzufügen",
  "friendCode": "Freundescode",
  "wins": "Siege",
  "losses": "Niederlagen",
  "explanation": "Erklärung",
  "tips": "Tipps",
  "correct": "Richtig!",
  "incorrect": "Falsch",
  "nextQuestion": "Nächste Frage",
  "finishQuiz": "Quiz beenden",
  "checkAnswer": "Antwort prüfen",
  "cancel": "Abbrechen",
  "add": "Hinzufügen",
  "save": "Speichern",
  "noFriends": "Noch keine Freunde. Füge Freunde hinzu, um zu konkurrieren!"
}
```

**File**: `lib/l10n/l10n.yaml`

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

### 3. Theme Management

**File**: `lib/theme/app_theme.dart`

```dart
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.light,
    ),
    // ... additional theme properties
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.dark,
    ),
    // ... additional theme properties
  );
}
```

**File**: `lib/providers/theme_providers.dart`

```dart
class ThemeNotifier extends StateNotifier<ThemeMode> {
  final SettingsService _settingsService;

  ThemeNotifier(this._settingsService) : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final isDark = await _settingsService.getDarkMode();
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _settingsService.setDarkMode(newMode == ThemeMode.dark);
    state = newMode;
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return ThemeNotifier(settingsService);
});
```

### 4. Locale Management

**File**: `lib/providers/locale_providers.dart`

```dart
class LocaleNotifier extends StateNotifier<Locale> {
  final SettingsService _settingsService;

  LocaleNotifier(this._settingsService) : super(const Locale('en')) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final languageCode = await _settingsService.getLanguage();
    state = Locale(languageCode ?? 'en');
  }

  Future<void> setLocale(String languageCode) async {
    await _settingsService.setLanguage(languageCode);
    state = Locale(languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return LocaleNotifier(settingsService);
});
```

### 5. Settings Service Extension

**File**: `lib/services/settings_service.dart` (additions)

```dart
class SettingsService {
  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;

  // Existing methods...

  Future<bool> getDarkMode() async {
    return _prefs.getBool('darkMode') ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    await _prefs.setBool('darkMode', value);
  }

  Future<String?> getLanguage() async {
    return _prefs.getString('language');
  }

  Future<void> setLanguage(String languageCode) async {
    await _prefs.setString('language', languageCode);
  }

  Future<String?> getAvatarPath() async {
    return _prefs.getString('avatarPath');
  }

  Future<void> setAvatarPath(String path) async {
    await _prefs.setString('avatarPath', path);
  }
}
```

### 6. Dashboard Redesign

**File**: `lib/screens/home/home_screen.dart`

```dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userDataProvider);
    final categories = ref.watch(categoriesProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with crown and correct answers
            _buildHeader(context, user, l10n),

            // Dashboard background image
            _buildDashboardImage(),

            // Categories grid
            Expanded(
              child: categories.when(
                data: (cats) => _buildCategoriesGrid(cats, l10n),
                loading: () => CircularProgressIndicator(),
                error: (e, st) => Text('Error: $e'),
              ),
            ),

            // Start Random Quiz button
            _buildRandomQuizButton(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AsyncValue<UserModel> user, AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, color: Colors.amber, size: 32),
          SizedBox(width: 8),
          user.when(
            data: (u) => Text(
              '${u.totalCorrectAnswers} ${l10n.correctAnswers}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            loading: () => CircularProgressIndicator(),
            error: (_, __) => Text('--'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid(List<Category> categories, AppLocalizations l10n) {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return CategoryCard(category: categories[index]);
      },
    );
  }
}
```

### 7. Category Card Widget

**File**: `lib/widgets/category_card.dart`

```dart
class CategoryCard extends StatelessWidget {
  final Category category;

  const CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final iconPath = category.iconName != null
        ? 'assets/app_images/categories/${category.iconName}.png'
        : 'assets/app_images/categories/default.png';

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuizLengthScreen(categoryId: category.id),
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconPath,
              width: 64,
              height: 64,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/app_images/categories/default.png',
                width: 64,
                height: 64,
              ),
            ),
            SizedBox(height: 8),
            Text(
              category.title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

### 8. VS Mode Friends Screen

**File**: `lib/screens/vs_mode/vs_mode_friends_screen.dart`

```dart
class VSModeFriendsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.vsMode),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: () => _showAddFriendDialog(context, ref, l10n),
          ),
        ],
      ),
      body: friends.when(
        data: (friendsList) {
          if (friendsList.isEmpty) {
            return Center(
              child: Text(l10n.noFriends),
            );
          }
          return ListView.builder(
            itemCount: friendsList.length,
            itemBuilder: (context, index) {
              return FriendListItem(friend: friendsList[index]);
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showAddFriendDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addFriend),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.friendCode,
            hintText: 'ABC123',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final friendsService = ref.read(friendsServiceProvider);
              await friendsService.addFriendByCode(controller.text);
              Navigator.pop(context);
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }
}
```

### 9. Friend List Item Widget

**File**: `lib/widgets/friend_list_item.dart`

```dart
class FriendListItem extends StatelessWidget {
  final Friend friend;

  const FriendListItem({required this.friend});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: AssetImage(
            friend.avatarPath ?? 'assets/app_images/avatars/avatar_1.png',
          ),
        ),
        title: Text(friend.displayName),
        subtitle: Row(
          children: [
            Icon(Icons.emoji_events, size: 16, color: Colors.green),
            SizedBox(width: 4),
            Text('${friend.wins} ${l10n.wins}'),
            SizedBox(width: 16),
            Icon(Icons.close, size: 16, color: Colors.red),
            SizedBox(width: 4),
            Text('${friend.losses} ${l10n.losses}'),
          ],
        ),
        trailing: Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VSModeSetupScreen(friendId: friend.userId),
            ),
          );
        },
      ),
    );
  }
}
```

### 10. Settings Screen Redesign

**File**: `lib/screens/settings/settings_screen.dart`

```dart
class SettingsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          // Dark Mode Toggle
          SwitchListTile(
            title: Text(l10n.darkMode),
            value: themeMode == ThemeMode.dark,
            onChanged: (_) {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),

          // Language Selection
          ListTile(
            title: Text(l10n.language),
            subtitle: Text(locale.languageCode == 'de' ? 'Deutsch' : 'English'),
            trailing: Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(context, ref, l10n),
          ),

          // Change Avatar
          ListTile(
            title: Text(l10n.changeAvatar),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AvatarSelectionScreen()),
              );
            },
          ),

          Divider(),

          // Logout
          ListTile(
            title: Text(l10n.logout),
            leading: Icon(Icons.logout, color: Colors.red),
            onTap: () async {
              final authService = ref.read(authServiceProvider);
              await authService.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('English'),
              value: 'en',
              groupValue: ref.read(localeProvider).languageCode,
              onChanged: (value) {
                ref.read(localeProvider.notifier).setLocale(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('Deutsch'),
              value: 'de',
              groupValue: ref.read(localeProvider).languageCode,
              onChanged: (value) {
                ref.read(localeProvider.notifier).setLocale(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

### 11. Avatar Selection Screen

**File**: `lib/screens/settings/avatar_selection_screen.dart`

```dart
class AvatarSelectionScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends ConsumerState<AvatarSelectionScreen> {
  String? _selectedAvatar;

  final List<String> _avatars = [
    'assets/app_images/avatars/avatar_1.png',
    'assets/app_images/avatars/avatar_2.png',
    'assets/app_images/avatars/avatar_3.png',
    'assets/app_images/avatars/avatar_4.png',
    'assets/app_images/avatars/avatar_5.png',
    'assets/app_images/avatars/avatar_6.png',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.changeAvatar),
        actions: [
          TextButton(
            onPressed: _selectedAvatar != null ? _saveAvatar : null,
            child: Text(l10n.save),
          ),
        ],
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _avatars.length,
        itemBuilder: (context, index) {
          final avatar = _avatars[index];
          final isSelected = _selectedAvatar == avatar;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedAvatar = avatar);
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                backgroundImage: AssetImage(avatar),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveAvatar() async {
    if (_selectedAvatar == null) return;

    final settingsService = ref.read(settingsServiceProvider);
    await settingsService.setAvatarPath(_selectedAvatar!);

    Navigator.pop(context);
  }
}
```

### 12. Quiz Explanation Screen with Tips

**File**: `lib/screens/quiz/quiz_explanation_screen.dart` (enhancements)

The explanation screen already displays tips when available. Enhancements needed:

```dart
// Tips section styling (already implemented, needs i18n)
if (question.tips != null) ...[
  const SizedBox(height: 24),
  Text(
    l10n.tips,  // Add to ARB files
    style: Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
    ),
  ),
  const SizedBox(height: 12),
  Card(
    color: Colors.blue.shade50,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              question.tips!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    ),
  ),
],
```

**Required i18n additions:**

- "Explanation" label
- "Tips" label
- "Correct!" / "Incorrect" messages
- "Next Question" / "Finish Quiz" button text

### 13. Main App Configuration

**File**: `lib/main.dart` (modifications)

```dart
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Parent Quiz',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en'),
        Locale('de'),
      ],
      home: AuthWrapper(),
    );
  }
}
```

## Data Models

### App Settings Model

**File**: `lib/models/app_settings.dart`

```dart
class AppSettings {
  final bool darkMode;
  final String languageCode;
  final String? avatarPath;

  AppSettings({
    required this.darkMode,
    required this.languageCode,
    this.avatarPath,
  });

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      darkMode: map['darkMode'] ?? false,
      languageCode: map['languageCode'] ?? 'en',
      avatarPath: map['avatarPath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'darkMode': darkMode,
      'languageCode': languageCode,
      'avatarPath': avatarPath,
    };
  }
}
```

### Friend Model Extension

**File**: `lib/models/friend.dart` (additions)

```dart
class Friend {
  final String userId;
  final String displayName;
  final String? avatarPath;
  final int wins;
  final int losses;
  final String status;
  final DateTime createdAt;

  // Existing fields and methods...

  int get totalGames => wins + losses;
  double get winRate => totalGames > 0 ? wins / totalGames : 0.0;
}
```

## Correctness Properties

_A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees._

### Property 1: Navigation state consistency

_For any_ navigation action, the selected tab index should match the displayed screen
**Validates: Requirements 1.2, 1.3**

### Property 2: Category icon fallback

_For any_ category without a specific icon, the system should display the default icon
**Validates: Requirements 2.4**

### Property 3: Language persistence

_For any_ language selection, restarting the app should preserve the selected language
**Validates: Requirements 5.2**

### Property 4: Theme persistence

_For any_ theme toggle, restarting the app should preserve the selected theme
**Validates: Requirements 4.2**

### Property 5: Avatar selection validation

_For any_ avatar selection, the saved avatar path should be a valid asset path
**Validates: Requirements 6.3**

### Property 6: Translation fallback

_For any_ missing translation key, the system should fall back to English
**Validates: Requirements 5.4**

### Property 7: Friend list ordering

_For any_ friends list, friends should be ordered consistently (e.g., by display name or win rate)
**Validates: Requirements 3.2**

### Property 8: Locale change propagation

_For any_ locale change, all visible UI text should update to the new language
**Validates: Requirements 4.3**

## Error Handling

### Translation Errors

- Missing translation keys fall back to English
- Log warnings for missing translations in development mode
- Display key name if both primary and fallback translations are missing

### Asset Loading Errors

- Category icons fall back to default.png if specific icon is missing
- Avatar images fall back to avatar_1.png if selected avatar is missing
- Dashboard background uses a solid color if image fails to load

### Settings Persistence Errors

- If SharedPreferences fails, use in-memory defaults
- Retry settings save operations with exponential backoff
- Display error message to user if settings cannot be saved after retries

### Navigation Errors

- Validate navigation indices before state updates
- Handle invalid routes gracefully with error screen
- Log navigation errors for debugging

## Testing Strategy

### Unit Tests

**Theme Management Tests**:

- Test theme toggle updates state correctly
- Test theme persistence to SharedPreferences
- Test theme loading on app start

**Locale Management Tests**:

- Test locale change updates state correctly
- Test locale persistence to SharedPreferences
- Test locale loading on app start
- Test fallback to device locale

**Settings Service Tests**:

- Test dark mode get/set operations
- Test language get/set operations
- Test avatar path get/set operations

**Category Icon Resolution Tests**:

- Test icon path resolution for existing icons
- Test fallback to default icon for missing icons
- Test icon path construction

### Property-Based Tests

**Property Testing Framework**: Use `test` package with custom generators

**Property 1: Navigation Consistency**

```dart
// Generate random navigation indices
// Verify selected index matches displayed screen
```

**Property 2: Category Icon Fallback**

```dart
// Generate categories with and without icon names
// Verify all categories display an icon (specific or default)
```

**Property 3: Language Persistence**

```dart
// Generate random language selections
// Verify language persists across app restarts
```

**Property 4: Theme Persistence**

```dart
// Generate random theme toggles
// Verify theme persists across app restarts
```

**Property 5: Avatar Selection Validation**

```dart
// Generate random avatar selections
// Verify saved paths are valid asset paths
```

**Property 6: Translation Fallback**

```dart
// Generate random translation keys (some missing)
// Verify fallback to English for missing keys
```

**Property 7: Friend List Ordering**

```dart
// Generate random friend lists
// Verify consistent ordering
```

**Property 8: Locale Change Propagation**

```dart
// Generate random locale changes
// Verify all UI text updates
```

### Integration Tests

- Test complete navigation flow through all tabs
- Test language change updates all screens
- Test theme change updates all screens
- Test avatar selection and display
- Test friend addition and display in VS Mode
- Test category selection and quiz start
- Test settings persistence across app restarts

### Widget Tests

- Test BottomNavigationBar displays correct items
- Test CategoryCard displays icon and title
- Test FriendListItem displays friend data
- Test SettingsScreen displays all options
- Test AvatarSelectionScreen displays avatar grid
- Test language dialog displays supported languages
