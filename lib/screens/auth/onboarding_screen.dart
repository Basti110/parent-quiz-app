import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingPage> _getPages(AppLocalizations l10n) {
    return [
      OnboardingPage(
        title: l10n.welcomeToParentQuiz,
        description: l10n.onboardingWelcomeDescription,
        icon: Icons.family_restroom,
      ),
      OnboardingPage(
        title: l10n.earnXpLevelUp,
        description: l10n.onboardingXpDescription,
        icon: Icons.emoji_events,
      ),
      OnboardingPage(
        title: l10n.competeWithFriends,
        description: l10n.onboardingFriendsDescription,
        icon: Icons.people,
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    final l10n = AppLocalizations.of(context)!;
    final pages = _getPages(l10n);

    if (_currentPage < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = _getPages(l10n);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(pages[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      pages.length,
                      (index) => _buildPageIndicator(index),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0)
                        TextButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Text(l10n.back),
                        )
                      else
                        const SizedBox(width: 80),
                      ElevatedButton(
                        onPressed: _nextPage,
                        child: Text(
                          _currentPage == pages.length - 1
                              ? l10n.getStarted
                              : l10n.next,
                        ),
                      ),
                      if (_currentPage < pages.length - 1)
                        TextButton(
                          onPressed: _completeOnboarding,
                          child: Text(l10n.skip),
                        )
                      else
                        const SizedBox(width: 80),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(page.icon, size: 120, color: Theme.of(context).primaryColor),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 12 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? Theme.of(context).primaryColor
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
  });
}
