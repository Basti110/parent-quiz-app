# Manual Localization Testing Checklist

This checklist covers comprehensive manual testing validation for the UI redesign i18n feature.

## Test Environment Setup

- [ ] Flutter app running on device/emulator
- [ ] Both English and German locales available
- [ ] Language switching functionality accessible in settings

## 1. Complete App Navigation in Both Languages

### English Navigation Test
- [ ] Navigate to Dashboard - verify all text is in English
- [ ] Navigate to VS Mode - verify all screen titles and content
- [ ] Navigate to Leaderboard - verify all labels and messages
- [ ] Navigate to Friends - verify all friend-related text
- [ ] Navigate to Statistics - verify all statistics labels
- [ ] Navigate to Settings - verify all settings options

### German Navigation Test
- [ ] Switch language to German in settings
- [ ] Navigate to Dashboard - verify all text is in German
- [ ] Navigate to VS Mode - verify all screen titles and content
- [ ] Navigate to Leaderboard - verify all labels and messages
- [ ] Navigate to Friends - verify all friend-related text
- [ ] Navigate to Statistics - verify all statistics labels
- [ ] Navigate to Settings - verify all settings options

### Cross-Screen Consistency
- [ ] Verify consistent terminology across all screens in English
- [ ] Verify consistent terminology across all screens in German
- [ ] Check that navigation elements use the same terms throughout

## 2. Text Layout and Truncation Issues

### German Text Length Testing
German text is typically 20-30% longer than English. Test for:

- [ ] AppBar titles don't truncate or overflow
- [ ] Button labels fit properly within button boundaries
- [ ] Dialog titles and content display completely
- [ ] Form field labels don't overlap with input fields
- [ ] Status messages display fully in SnackBars
- [ ] Navigation tab labels fit within tab boundaries

### Screen Size Testing
Test on different screen sizes:
- [ ] Small screen (iPhone SE) - verify no text truncation
- [ ] Medium screen (iPhone 12) - verify proper layout
- [ ] Large screen (iPad) - verify text scaling

### Orientation Testing
- [ ] Portrait mode - all text displays properly
- [ ] Landscape mode - all text displays properly

## 3. Error Scenarios in Both Languages

### Network Errors
- [ ] Disconnect network and trigger errors
- [ ] Verify error messages display in correct language
- [ ] Test error messages in:
  - [ ] Friends loading
  - [ ] Leaderboard loading
  - [ ] Statistics loading
  - [ ] Duel operations
  - [ ] VS Mode operations

### Validation Errors
- [ ] Test form validation errors in English:
  - [ ] Empty friend code
  - [ ] Invalid friend code length
  - [ ] Empty player names in VS Mode
  - [ ] Category selection validation
- [ ] Test same validation errors in German
- [ ] Verify error messages are clear and helpful

### Authentication Errors
- [ ] Test login/logout errors in both languages
- [ ] Verify "User not authenticated" messages
- [ ] Test registration errors in both languages

## 4. Interactive Elements Testing

### Buttons and Actions
Test all buttons in both languages:
- [ ] "Accept" / "Akzeptieren" buttons
- [ ] "Decline" / "Ablehnen" buttons
- [ ] "Cancel" / "Abbrechen" buttons
- [ ] "Start Duel" / "Duell starten" buttons
- [ ] "Go Back" / "Zurück" buttons
- [ ] "Play Again" / "Nochmal spielen" buttons

### Dialogs and Modals
- [ ] Add Friend dialog - test in both languages
- [ ] Exit Duel dialog - test in both languages
- [ ] Duel Challenge dialog - test in both languages
- [ ] Confirmation dialogs - test in both languages

### Form Fields
- [ ] Friend code input - placeholder and labels
- [ ] Player name inputs - labels and validation
- [ ] Language selection - verify native language names

## 5. Game-Specific Content Testing

### VS Mode Content
- [ ] "VS" text displays correctly
- [ ] "Questions" / "Fragen" label
- [ ] "Time" / "Zeit" label
- [ ] "Winner" / "Gewinner" label
- [ ] Player turn instructions
- [ ] Score displays and labels

### Duel Content
- [ ] Duel challenge messages
- [ ] Progress indicators
- [ ] Status messages (sent, waiting, completed)
- [ ] Result displays

### Status Messages and Notifications
- [ ] Friend request sent notifications
- [ ] Duel challenge sent notifications
- [ ] Success messages (friend added, etc.)
- [ ] Info messages (friend code copied, etc.)
- [ ] Loading states and empty states

## 6. Language Switching Functionality

### Real-time Language Switching
- [ ] Switch from English to German - verify immediate update
- [ ] Switch from German to English - verify immediate update
- [ ] Verify no app restart required
- [ ] Test switching while on different screens

### Persistence Testing
- [ ] Switch language and restart app
- [ ] Verify language preference is saved
- [ ] Test with app backgrounding/foregrounding

## 7. Edge Cases and Special Scenarios

### Empty States
- [ ] No friends list - verify empty state message
- [ ] No categories available - verify message
- [ ] No leaderboard data - verify message

### Long Text Testing
- [ ] Test with very long friend names
- [ ] Test with long category names
- [ ] Verify text wrapping and ellipsis behavior

### Special Characters
- [ ] Test German umlauts (ä, ö, ü, ß) display correctly
- [ ] Test special punctuation in German text
- [ ] Verify character encoding is correct

## 8. Performance and Responsiveness

### Language Switching Performance
- [ ] Language switch happens within 1 second
- [ ] No visible lag or flickering during switch
- [ ] Memory usage remains stable

### App Startup Performance
- [ ] App starts quickly with German locale
- [ ] No delays in loading localized strings
- [ ] Initial screen displays immediately

## 9. Accessibility Testing

### Screen Reader Testing (if available)
- [ ] Test with VoiceOver (iOS) or TalkBack (Android)
- [ ] Verify localized text is read correctly
- [ ] Test in both English and German

### High Contrast and Large Text
- [ ] Test with system large text settings
- [ ] Test with high contrast mode
- [ ] Verify text remains readable

## 10. Final Validation Checklist

### No Hardcoded Strings
- [ ] Scan all visible text for hardcoded English strings in German mode
- [ ] Verify no "Error loading", "Failed to", "Please enter" in German
- [ ] Check for any untranslated button labels or messages

### Translation Quality (if German speaker available)
- [ ] Verify German translations are accurate
- [ ] Check for proper German grammar and syntax
- [ ] Ensure translations sound natural to native speakers

### Consistency Checks
- [ ] Same terms used consistently across the app
- [ ] UI conventions follow platform standards
- [ ] Error messages are helpful and clear

## Test Results Summary

Date: ___________
Tester: ___________
Device/Platform: ___________

### Issues Found:
- [ ] No issues found
- [ ] Minor issues (list below)
- [ ] Major issues (list below)

### Issue Details:
1. ________________________________
2. ________________________________
3. ________________________________

### Overall Assessment:
- [ ] Localization implementation is complete and working correctly
- [ ] Minor issues that don't affect core functionality
- [ ] Major issues that need to be addressed

### Recommendations:
_________________________________
_________________________________
_________________________________