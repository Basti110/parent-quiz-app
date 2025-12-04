import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
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
import 'screens/settings/settings_screen.dart';
import 'providers/auth_providers.dart';
import 'providers/settings_providers.dart';

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
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'ParentQuiz',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
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
        // If user is authenticated, show home screen
        if (user != null) {
          return const HomeScreen();
        }
        // If not authenticated, show onboarding
        return const OnboardingScreen();
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) {
        // On error, default to onboarding screen
        return const OnboardingScreen();
      },
    );
  }
}
