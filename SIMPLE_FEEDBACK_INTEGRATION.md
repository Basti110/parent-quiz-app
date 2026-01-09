# Einfaches Fragen-Feedback Integration

## Übersicht

Das `SimpleQuestionFeedbackWidget` ist ein minimalistisches "Fehler melden" Widget für Fragen. Es bietet:

- **Einfache Bedienung**: Nur ein "Fehler melden" Button
- **Optionales Textfeld**: Benutzer können Details angeben, müssen aber nicht
- **Kompaktes Design**: Nimmt wenig Platz ein, erweitert sich nur bei Bedarf
- **Deutschsprachig**: Vollständig auf Deutsch lokalisiert

## Schnelle Integration

### 1. Import hinzufügen

```dart
import '../../widgets/simple_question_feedback_widget.dart';
```

### 2. Widget in Quiz-Screen einfügen

Füge das Widget nach den Antwortoptionen hinzu:

```dart
// Answer options
...List.generate(question.options.length, (index) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: _buildAnswerOption(question, index),
  );
}),

const SizedBox(height: 16),

// FEEDBACK-WIDGET HIER HINZUFÜGEN
SimpleQuestionFeedbackWidget(
  question: question,
  categoryName: categoryName, // z.B. "Ernährung" oder "Gemischte Kategorien"
),
```

### 3. Kategorie-Name bestimmen

```dart
// Beispiel für Kategorie-Name
final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
final category = args['category'] as Category?;
final categoryName = category?.title ?? 'Gemischte Kategorien';
```

## Verwendung in verschiedenen Quiz-Screens

### Standard Quiz-Screen
```dart
// In lib/screens/quiz/quiz_screen.dart
SimpleQuestionFeedbackWidget(
  question: question,
  categoryName: category?.title ?? 'Gemischte Kategorien',
)
```

### Duel Quiz-Screen
```dart
// In lib/screens/duel/duel_question_screen.dart
SimpleQuestionFeedbackWidget(
  question: question,
  categoryName: 'Duel', // oder spezifische Kategorie
)
```

### VS Mode Quiz-Screen
```dart
// In lib/screens/vs_mode/vs_mode_quiz_screen.dart
SimpleQuestionFeedbackWidget(
  question: question,
  categoryName: 'VS Mode', // oder spezifische Kategorie
)
```

## Widget-Features

### Benutzeroberfläche
- **Kollabierbar**: Standardmäßig eingeklappt, erweitert sich bei Klick
- **Rotes Icon**: Deutlich als "Fehler melden" erkennbar
- **Optionales Textfeld**: Benutzer können Details angeben oder leer lassen
- **Roter Submit-Button**: Konsistent mit "Fehler melden" Theme

### Funktionalität
- **Optionale Beschreibung**: Mindestens 5 Zeichen wenn Text eingegeben wird
- **Automatischer Fallback**: Wenn kein Text eingegeben wird: "Fehler bei Frage gemeldet (keine Details angegeben)"
- **Loading-Status**: Button zeigt Spinner während Übertragung
- **Erfolgs-Feedback**: Grüne Snackbar bei erfolgreichem Senden
- **Formular-Reset**: Klappt automatisch zusammen nach erfolgreichem Senden

### Datenstruktur
Das Widget verwendet die bestehende `QuestionFeedback` Struktur:
```dart
{
  type: 'question',
  user_comment: 'Benutzer-Text oder Fallback-Text',
  question_id: 'frage-id',
  category: 'Kategorie-Name',
  issue_type: 'other', // Immer 'other' für generelles Feedback
  // ... weitere Felder
}
```

## Styling

### Farben
- **Icon**: `AppColors.error` (rot)
- **Button**: `AppColors.error` Hintergrund, weiße Schrift
- **Border**: Standard App-Border-Farben

### Layout
- **Margin**: 16px horizontal, 8px vertikal
- **Padding**: 16px innen
- **Border-Radius**: 12px (konsistent mit App-Design)
- **Textfeld**: 3 Zeilen hoch, 8px Border-Radius

## Beispiel-Integration in bestehenden Screen

```dart
// In deinem bestehenden Quiz-Screen
child: Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    // Bestehende Frage und Antworten
    _buildQuestionCard(question),
    const SizedBox(height: 24),
    
    // Antwortoptionen
    ...List.generate(question.options.length, (index) {
      return _buildAnswerOption(question, index);
    }),
    
    const SizedBox(height: 16),
    
    // NEUES FEEDBACK-WIDGET
    SimpleQuestionFeedbackWidget(
      question: question,
      categoryName: _getCategoryName(),
    ),
  ],
),
```

## Debugging

Das Widget enthält ausführliche Console-Logs:
- Formular-Validierung
- Benutzer-Authentifizierung
- Feedback-Erstellung
- Firestore-Übertragung
- UI-Updates

Schaue in die Console für Details bei Problemen.

## Anpassungen

### Text ändern
```dart
// In simple_question_feedback_widget.dart
'Fehler melden' → 'Problem melden'
'Beschreibe das Problem...' → 'Was ist das Problem?'
```

### Farbe ändern
```dart
// Icon und Button Farbe
AppColors.error → AppColors.warning // für orange
```

### Mindest-Textlänge
```dart
// Validation
value.trim().length < 5 → value.trim().length < 10 // für 10 Zeichen
```

## Vollständiges Beispiel

Siehe `lib/screens/quiz/quiz_screen_with_simple_feedback.dart` für ein vollständiges Beispiel der Integration.

Das Widget ist sofort einsatzbereit und erfordert nur das Hinzufügen von 3-4 Zeilen Code in deine bestehenden Quiz-Screens!