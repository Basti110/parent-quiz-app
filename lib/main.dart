import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/settings/avatar_selection_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/quiz/category_selection_screen.dart';
import 'screens/quiz/quiz_length_screen.dart';
import 'screens/quiz/quiz_screen.dart';
import 'screens/quiz/quiz_explanation_screen.dart';
import 'screens/quiz/quiz_result_screen.dart';
import 'screens/leaderboard/leaderboard_screen.dart';
import 'screens/friends/friends_screen.dart';
import 'screens/vs_mode/vs_mode_setup_screen.dart';
import 'screens/vs_mode/vs_mode_quiz_screen.dart';
import 'screens/vs_mode/vs_mode_handoff_screen.dart';
import 'screens/vs_mode/vs_mode_result_screen.dart';
import 'screens/duel/duel_challenge_screen.dart';
import 'screens/duel/duel_question_screen.dart';
import 'screens/duel/duel_result_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'providers/auth_providers.dart';
import 'providers/theme_providers.dart';
import 'providers/locale_providers.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Disable App Check enforcement for development
  await FirebaseAuth.instance.setSettings(
    appVerificationDisabledForTesting: true,
  );

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Eduparo',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('de')],
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/welcome': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return WelcomeScreen(userId: args?['userId'] as String?);
        },
        '/avatar-selection': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return AvatarSelectionScreen(
            isRegistrationFlow: args['isRegistrationFlow'] as bool,
            userId: args['userId'] as String,
          );
        },
        '/home': (context) => const MainNavigationScreen(),
        '/category-selection': (context) => const CategorySelectionScreen(),
        '/quiz-length': (context) => const QuizLengthScreen(),
        '/quiz': (context) => const QuizScreen(),
        '/quiz-explanation': (context) => const QuizExplanationScreen(),
        '/quiz-result': (context) => const QuizResultScreen(),
        '/leaderboard': (context) => const LeaderboardScreen(),
        '/friends': (context) => const FriendsScreen(),
        '/vs-mode-setup': (context) => const VSModeSetupScreen(),
        '/vs-mode-quiz': (context) => const VSModeQuizScreen(),
        '/vs-mode-handoff': (context) => const VSModeHandoffScreen(),
        '/vs-mode-result': (context) => const VSModeResultScreen(),
        '/duel-challenge': (context) => const DuelChallengeScreen(),
        '/duel-question': (context) => const DuelQuestionScreen(),
        '/duel-result': (context) => const DuelResultScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

/// AuthGate widget that handles initial route based on authentication state
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        // If user is authenticated, show main navigation screen
        if (user != null) {
          return const MainNavigationScreen();
        }
        // If not authenticated, show login screen
        return const LoginScreen();
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) {
        // On error, default to login screen
        return const LoginScreen();
      },
    );
  }
}
