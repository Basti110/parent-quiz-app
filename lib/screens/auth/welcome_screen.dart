import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  final String? userId;

  const WelcomeScreen({
    super.key,
    this.userId,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<WelcomePage> _pages = [
    WelcomePage(
      content:
          'Schön, dass ihr hier seid.\n\nWer steckt eigentlich hinter dieser App?\n\nWir sind Sebastian und Nele.',
    ),
    WelcomePage(
      content:
          'Sebastian ist Softwareentwickler und Nele Sozialarbeiterin beim allgemeinen sozialen Dienst (Jugendamt).\n\nAls wir selbst Eltern wurden, fiel uns etwas Kurioses auf: Es gibt unzählige Kurse, um sich auf die Geburt vorzubereiten – aber kaum welche, die einen auf das Kind vorbereiten!',
    ),
    WelcomePage(
      content:
          'In Anbetracht der Tatsache, dass man bei der Erziehung des Kindes die alleinige Verantwortung hat (das kann, wie wir finden, schon mal beängstigend sein), fanden wir das sehr schade.\n\nNatürlich gibt es tausende Ratgeber-Bücher, aber seien wir mal ehrlich: Wer hat im Alltag schon die Zeit und Lust, sich durch hunderte Seiten Theorie zu wälzen (vielleicht sind wir auch nur faul, aber wir haben uns damit schwer getan).',
    ),
    WelcomePage(
      content:
          'Da wir beide kleine spielerische Konkurrenzkämpfe lieben, entstand die Idee zu dieser App:\n\nFundiertes Wissen über Kinder von der Schwangerschaft bis zum ca. 3. Lebensjahr, aber als Spiel verpackt.',
    ),
    WelcomePage(
      content:
          'Bevor ihr loslegt, ist uns eines ganz wichtig:\n\nEs gibt keine perfekten Eltern. Auch wir (trotz Pädagogik-Studium!) machen nicht immer alles "richtig". Wissen und Handeln sind zwei verschiedene Paar Schuhe – besonders um 3 Uhr nachts bei Schlafmangel.',
    ),
    WelcomePage(
      content:
          'Verzweifelt also bitte nicht, wenn ihr am Anfang Fragen falsch beantwortet!\n\nDas macht euch nicht zu schlechten Eltern. Unser Ziel ist es lediglich, euch spielerisch Wissen zu vermitteln, damit vielleicht der ein oder andere nützliche Fakt hängen bleibt.',
    ),
    WelcomePage(
      content:
          'Ein kleiner Hinweis zu den Antworten:\n\nErziehung ist vielfältig. Wir beziehen uns in den Fragen immer auf den aktuellen wissenschaftlichen Konsens oder nennen explizit die Quelle (z.B. "Laut Montessori...").\n\nSeht das bitte nicht als strenges Regelwerk, dem ihr blind folgen müsst, sondern als wertvollen Gedankenanstoß für euren eigenen Weg.',
    ),
    WelcomePage(
      content:
          'Und jetzt: Viel Spaß beim Quizzen!\n\nSebastian und Nele',
      isLast: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _animationController.reset();
    _animationController.forward();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeWelcome();
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _completeWelcome() {
    // If userId is provided, go to avatar selection (post-registration)
    // Otherwise, go to registration form (pre-registration)
    if (widget.userId != null) {
      Navigator.of(context).pushReplacementNamed(
        '/avatar-selection',
        arguments: {
          'isRegistrationFlow': true,
          'userId': widget.userId,
        },
      );
    } else {
      Navigator.of(context).pushReplacementNamed('/register');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Penguin mascot at the top with animation
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: const EdgeInsets.only(top: 32, bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/app_symbol.png',
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.family_restroom,
                      size: 100,
                      color: colorScheme.primary,
                    );
                  },
                ),
              ),
            ),
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            // Navigation controls
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _buildPageIndicator(index),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Navigation buttons
                  Row(
                    children: [
                      // Back button
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _previousPage,
                            icon: const Icon(Icons.arrow_back, size: 20),
                            label: const Text('Zurück'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      if (_currentPage > 0) const SizedBox(width: 12),
                      // Next/Finish button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? 'Los geht\'s! 🚀'
                                : 'Weiter',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Skip button (only show on first few pages)
                      if (_currentPage < _pages.length - 2) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextButton(
                            onPressed: _completeWelcome,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Überspringen'),
                          ),
                        ),
                      ],
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

  Widget _buildPage(WelcomePage page) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                page.content,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 17,
                  height: 1.7,
                  color: colorScheme.onSurface,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (page.isLast) ...[
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/app_symbol.png',
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.family_restroom,
                      size: 80,
                      color: colorScheme.primary,
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = _currentPage == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.primary
            : colorScheme.onSurface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class WelcomePage {
  final String content;
  final bool isLast;

  WelcomePage({
    required this.content,
    this.isLast = false,
  });
}
