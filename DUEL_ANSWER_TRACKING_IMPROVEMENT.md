# Duel Answer Tracking - Verbesserungsvorschlag

## Aktueller Zustand

Das Duel System speichert derzeit nur:
```dart
Map<String, bool> challengerAnswers;  // questionId -> isCorrect
Map<String, bool> opponentAnswers;    // questionId -> isCorrect
```

**Problem**: Wir wissen nur, ob eine Antwort richtig oder falsch war, aber nicht welche spezifische Option (A, B, C, D) gewählt wurde.

## Vorgeschlagene Verbesserung

### 1. Erweiterte Datenstruktur

```dart
// Statt Map<String, bool>
Map<String, List<int>> challengerAnswers;  // questionId -> [selectedIndices]
Map<String, List<int>> opponentAnswers;    // questionId -> [selectedIndices]

// Zusätzlich für Kompatibilität
Map<String, bool> challengerCorrect;      // questionId -> isCorrect (berechnet)
Map<String, bool> opponentCorrect;        // questionId -> isCorrect (berechnet)
```

### 2. Firestore Schema Update

```dart
// Neue Felder in duels/{duelId}
{
  // Neue detaillierte Antworten
  'challengerSelectedAnswers': {
    'questionId1': [0, 2],  // Gewählte Optionen (A=0, C=2)
    'questionId2': [1],     // Gewählte Option (B=1)
  },
  'opponentSelectedAnswers': {
    'questionId1': [0],     // Gewählte Option (A=0)
    'questionId2': [1, 3],  // Gewählte Optionen (B=1, D=3)
  },
  
  // Bestehende Felder für Kompatibilität
  'challengerAnswers': {
    'questionId1': true,    // Berechnet aus selectedAnswers
    'questionId2': false,
  },
  'opponentAnswers': {
    'questionId1': false,
    'questionId2': true,
  },
}
```

### 3. UI Verbesserungen

Mit den detaillierten Daten könnten wir zeigen:

```dart
// Beispiel UI
A) Berlin          ✓ (Du)    ✗ (Gegner)    [Korrekt]
B) München         ✗         ✗             
C) Hamburg         ✗         ✓ (Gegner)    
D) Köln            ✗         ✗             

// Legende:
// ✓ = Gewählt und richtig
// ✗ = Nicht gewählt
// ✓ (rot) = Gewählt aber falsch
```

### 4. Migration Strategy

1. **Phase 1**: Neue Felder hinzufügen (optional)
2. **Phase 2**: Client-Code aktualisieren, um beide Formate zu schreiben
3. **Phase 3**: UI aktualisieren, um detaillierte Daten zu verwenden
4. **Phase 4**: Alte Felder als deprecated markieren

### 5. Implementierung

```dart
// DuelService Update
Future<void> submitAnswer({
  required String duelId,
  required String questionId,
  required List<int> selectedIndices,
  required List<int> correctIndices,
}) async {
  final isCorrect = _checkAnswer(selectedIndices, correctIndices);
  
  await _firestore.collection('duels').doc(duelId).update({
    // Neue detaillierte Daten
    'challengerSelectedAnswers.$questionId': selectedIndices,
    // Bestehende Kompatibilität
    'challengerAnswers.$questionId': isCorrect,
    'challengerScore': FieldValue.increment(isCorrect ? 1 : 0),
  });
}
```

## Vorteile der Verbesserung

✅ **Detaillierte Analyse**: Sehen, welche falschen Antworten gewählt wurden
✅ **Bessere UX**: Nutzer verstehen ihre Fehler besser
✅ **Analytics**: Bessere Daten für Fragen-Optimierung
✅ **Rückwärtskompatibilität**: Bestehende Duelle funktionieren weiter

## Aufwand

- **Backend**: Mittel (Schema-Update, Migration)
- **Frontend**: Mittel (UI-Update, neue Datenstrukturen)
- **Testing**: Hoch (Kompatibilität mit alten Duellen)

## Priorität

**Niedrig-Mittel** - Nice-to-have Feature, aber nicht kritisch für die Kernfunktionalität.

---

**Aktueller Workaround**: Die expandable Fragen zeigen A, B, C, D Labels und markieren korrekte Antworten grün. Nutzer sehen, was richtig gewesen wäre, auch wenn sie nicht sehen, was sie gewählt haben.