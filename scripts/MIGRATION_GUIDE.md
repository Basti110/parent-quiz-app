# Migration Guide: XP-Based to Streak-Based Gamification

## Overview

This guide provides step-by-step instructions for migrating your production database from the XP-based gamification system to the new simplified streak-based system.

## Prerequisites

- Access to Firebase Console
- Firebase CLI installed and authenticated
- Backup of production database
- Dart SDK installed (for running migration script)

## Migration Steps

### Step 1: Backup Database

**CRITICAL: Always backup your database before running any migration!**

#### Option A: Using Firebase Console

1. Go to Firebase Console → Firestore Database
2. Click on "Import/Export" tab
3. Click "Export"
4. Select a Cloud Storage bucket
5. Click "Export" and wait for completion
6. Note the export location for potential rollback

#### Option B: Using Firebase CLI

```bash
# Export entire database
gcloud firestore export gs://[BUCKET_NAME]/[EXPORT_PREFIX]

# Example:
gcloud firestore export gs://my-app-backups/migration-backup-2024-12-09
```

### Step 2: Verify Backup

1. Check that the export completed successfully
2. Verify the backup size is reasonable
3. Note the backup timestamp and location

### Step 3: Prepare Migration Script

1. Ensure you have the latest code:
   ```bash
   git pull origin main
   ```

2. Navigate to the scripts directory:
   ```bash
   cd scripts
   ```

3. Review the migration script:
   ```bash
   cat migrate_to_simplified_gamification.dart
   ```

### Step 4: Run Migration in Test Environment (Recommended)

Before running in production, test the migration:

1. Create a test Firebase project
2. Import a subset of production data
3. Run the migration script:
   ```bash
   dart migrate_to_simplified_gamification.dart
   ```
4. Verify the results manually
5. Test the app with migrated data

### Step 5: Schedule Maintenance Window

1. Notify users of scheduled maintenance
2. Choose a low-traffic time window
3. Plan for 30-60 minutes of downtime (depending on user count)

### Step 6: Run Production Migration

1. **Put app in maintenance mode** (if possible)
   - Disable new user registrations
   - Show maintenance message to users

2. **Run the migration script:**
   ```bash
   dart migrate_to_simplified_gamification.dart
   ```

3. **Monitor the output:**
   - Watch for any errors
   - Note the success/failure counts
   - Save the output log

4. **Example output:**
   ```
   === Simplified Gamification Migration Script ===
   
   Initializing Firebase...
   Found 1,234 users to migrate.
   
   [1/1234] Migrating user: abc123 (John Doe)
     ✓ Success
   
   [2/1234] Migrating user: def456 (Jane Smith)
     ✓ Success
   
   ...
   
   === Migration Summary ===
   Total users: 1,234
   Successful: 1,234
   Errors: 0
   
   Migration complete!
   ```

### Step 7: Verify Migration

1. **Check random user documents:**
   ```bash
   # Using Firebase Console
   # Navigate to Firestore → users collection
   # Open several random user documents
   # Verify:
   # - streakCurrent and streakLongest are preserved
   # - streakPoints = 0
   # - dailyGoal = 10
   # - questionsAnsweredToday = 0
   # - totalQuestionsAnswered = 0
   # - totalCorrectAnswers = 0
   # - totalMasteredQuestions matches questionStates count
   # - duelsCompleted = old duelsPlayed value
   # - duelsWon is preserved
   # - XP fields are removed (totalXp, currentLevel, etc.)
   ```

2. **Run verification queries:**
   ```javascript
   // In Firebase Console → Firestore
   
   // Check for any remaining XP fields
   db.collection('users')
     .where('totalXp', '!=', null)
     .get()
     .then(snapshot => console.log('Users with totalXp:', snapshot.size));
   
   // Should return 0
   ```

3. **Test the app:**
   - Login as a test user
   - Verify home screen shows daily progress
   - Verify leaderboard shows streak points
   - Verify settings shows daily goal adjustment
   - Complete a quiz and verify stats update correctly

### Step 8: Monitor for Issues

1. **Check error logs:**
   - Firebase Console → Functions → Logs
   - Look for any migration-related errors

2. **Monitor user reports:**
   - Watch for user complaints
   - Check support channels
   - Monitor app crash reports

3. **Verify data integrity:**
   - Run spot checks on user data
   - Verify questionStates are intact
   - Check that new features work correctly

### Step 9: Deploy Updated App

1. **Deploy new app version:**
   ```bash
   # Build and deploy to app stores
   flutter build apk --release
   flutter build ios --release
   ```

2. **Update Firestore security rules** (if needed)

3. **Update Firestore indexes:**
   - Deploy new indexes for streak points
   - Remove old indexes for weekly XP

### Step 10: Remove Maintenance Mode

1. Re-enable app access
2. Notify users that maintenance is complete
3. Monitor for any issues

## Rollback Procedure

If issues are discovered after migration:

### Option 1: Restore from Backup

```bash
# Restore entire database from backup
gcloud firestore import gs://[BUCKET_NAME]/[EXPORT_PREFIX]

# Example:
gcloud firestore import gs://my-app-backups/migration-backup-2024-12-09
```

### Option 2: Revert Individual Users

If only specific users have issues:

1. Identify affected user IDs
2. Restore their documents from backup
3. Manually fix any data inconsistencies

## Post-Migration Checklist

- [ ] All users migrated successfully
- [ ] No XP-related fields remain in user documents
- [ ] Streak data preserved correctly
- [ ] Question states intact
- [ ] New fields initialized with correct defaults
- [ ] App functions correctly with new schema
- [ ] Leaderboard displays streak points
- [ ] Daily goal system works
- [ ] No user complaints or issues reported
- [ ] Backup verified and stored safely
- [ ] Migration log saved for records

## Troubleshooting

### Issue: Migration script fails to connect to Firebase

**Solution:**
1. Verify Firebase credentials are configured
2. Check that Firebase project ID is correct
3. Ensure network connectivity

### Issue: Some users fail to migrate

**Solution:**
1. Check the error log for specific user IDs
2. Manually inspect those user documents
3. Fix any data inconsistencies
4. Re-run migration for failed users only

### Issue: Question states are missing after migration

**Solution:**
1. Question states should not be affected by migration
2. Check if they existed before migration
3. Restore from backup if necessary

### Issue: App crashes after migration

**Solution:**
1. Check app logs for specific errors
2. Verify all required fields are present
3. Check for null safety issues
4. Consider rolling back if critical

## Support

For issues or questions:
- Check Firebase Console logs
- Review migration test results
- Consult development team
- Refer to design document: `.kiro/specs/simplified-gamification/design.md`

## Migration Verification Script

You can use this script to verify migration success:

```dart
// scripts/verify_migration.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;
  
  print('Verifying migration...\n');
  
  // Check for remaining XP fields
  final xpUsers = await firestore
      .collection('users')
      .where('totalXp', isNull: false)
      .get();
  print('Users with totalXp field: ${xpUsers.docs.length}');
  
  // Check for new fields
  final allUsers = await firestore.collection('users').limit(10).get();
  int usersWithNewFields = 0;
  
  for (final doc in allUsers.docs) {
    final data = doc.data();
    if (data.containsKey('streakPoints') &&
        data.containsKey('dailyGoal') &&
        data.containsKey('questionsAnsweredToday')) {
      usersWithNewFields++;
    }
  }
  
  print('Sample users with new fields: $usersWithNewFields/10');
  
  if (xpUsers.docs.isEmpty && usersWithNewFields == 10) {
    print('\n✓ Migration appears successful!');
  } else {
    print('\n✗ Migration may have issues. Please investigate.');
  }
}
```

## Timeline Estimate

- **Small database (<100 users):** 5-10 minutes
- **Medium database (100-1,000 users):** 10-30 minutes
- **Large database (1,000-10,000 users):** 30-60 minutes
- **Very large database (>10,000 users):** 1-2 hours

Add buffer time for verification and testing.
