# Deploying Firestore Security Rules

## Prerequisites

1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Initialize Firebase in your project (if not already done):
   ```bash
   firebase init firestore
   ```
   - Select your Firebase project: `kiducation-a0d40`
   - Accept the default `firestore.rules` file location
   - Accept the default `firestore.indexes.json` file location

## Deploying Rules

### Deploy Security Rules Only

To deploy just the security rules without affecting other Firebase services:

```bash
firebase deploy --only firestore:rules
```

### Deploy Rules and Indexes Together

To deploy both security rules and indexes:

```bash
firebase deploy --only firestore
```

### Deploy Everything

To deploy all Firebase resources (rules, indexes, functions, hosting, etc.):

```bash
firebase deploy
```

## Testing Rules Locally

### Start Firebase Emulator

Test your rules locally before deploying to production:

```bash
firebase emulators:start --only firestore
```

This will start the Firestore emulator on `localhost:8080`.

### Run Tests Against Emulator

Configure your Flutter tests to use the emulator:

```dart
// In test setup
FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
```

Then run your tests:

```bash
flutter test
```

## Verifying Deployment

### Check Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `kiducation-a0d40`
3. Navigate to Firestore Database → Rules
4. Verify the rules match your `firestore.rules` file
5. Check the "Published" timestamp to confirm deployment

### Test in Production

After deployment, test key operations:

1. **User Profile Update**: Update daily goal in settings
2. **Duel Creation**: Challenge a friend to a duel
3. **Duel Participation**: Accept and complete a duel
4. **Leaderboard Access**: View leaderboard data
5. **Question Access**: Start a quiz and load questions

### Monitor for Errors

Check for security rule violations:

1. Go to Firestore → Usage tab
2. Look for denied read/write operations
3. Review error patterns
4. Adjust rules if legitimate operations are blocked

## Rollback

If you need to rollback to a previous version:

1. Go to Firebase Console → Firestore → Rules
2. Click on the "History" tab
3. Select a previous version
4. Click "Publish"

Or restore from your version control:

```bash
git checkout <previous-commit> -- firestore.rules
firebase deploy --only firestore:rules
```

## Common Issues

### Issue: Rules not taking effect

**Solution**: Rules can take a few minutes to propagate. Wait 2-3 minutes and try again.

### Issue: Permission denied errors

**Solution**: 
1. Check that the user is authenticated
2. Verify the user has the correct permissions
3. Review the specific rule that's being violated
4. Test the rule in the Firebase Console Rules Playground

### Issue: Rules too complex (timeout)

**Solution**: 
1. Simplify complex rules
2. Use helper functions to reduce duplication
3. Avoid deeply nested conditions

## Security Best Practices

1. **Test Before Deploying**: Always test rules in the emulator first
2. **Deploy During Low Traffic**: Deploy during off-peak hours
3. **Monitor After Deployment**: Watch for errors in the first hour
4. **Keep Backups**: Commit rules to version control before deploying
5. **Document Changes**: Update FIRESTORE_SECURITY_RULES.md with any changes
6. **Review Regularly**: Audit rules quarterly for security issues

## Related Files

- `firestore.rules` - The security rules file
- `firestore.indexes.json` - Firestore indexes configuration
- `FIRESTORE_SECURITY_RULES.md` - Detailed documentation
- `FIRESTORE_INDEXES.md` - Index documentation

## Support

For issues or questions:
1. Check [Firebase Security Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started)
2. Review [Firebase Console](https://console.firebase.google.com/)
3. Check Firebase Status: https://status.firebase.google.com/
