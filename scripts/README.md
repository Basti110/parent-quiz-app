# Migration Scripts

This directory contains scripts for migrating the database from XP-based gamification to the simplified streak-based system.

## Files

### migrate_to_simplified_gamification.dart

The main migration script that performs the database migration.

**What it does:**
- Preserves existing streak data (streakCurrent, streakLongest)
- Preserves question state data (in questionStates subcollection)
- Removes XP-related fields (totalXp, currentLevel, weeklyXpCurrent, weeklyXpWeekStart)
- Initializes new fields with defaults (streakPoints, dailyGoal, questionsAnsweredToday, etc.)
- Updates duel statistics (duelsPlayed → duelsCompleted, removes duelsLost and duelPoints)

**Usage:**
```bash
dart migrate_to_simplified_gamification.dart
```

**Requirements:**
- Firebase project configured
- Dart SDK installed
- Appropriate Firebase permissions

### verify_migration.dart

Verification script to check that migration completed successfully.

**What it checks:**
- XP-related fields are removed
- New fields are present and valid
- Streak data is preserved correctly
- Question states are intact
- Duel statistics are updated correctly

**Usage:**
```bash
dart verify_migration.dart
```

**When to use:**
- After running the migration script
- To verify migration success
- To troubleshoot migration issues

### MIGRATION_GUIDE.md

Comprehensive guide for running the migration in production.

**Contents:**
- Step-by-step migration instructions
- Backup procedures
- Verification steps
- Rollback procedures
- Troubleshooting guide
- Timeline estimates

**When to use:**
- Before running migration in production
- As a reference during migration
- For planning maintenance windows

## Migration Workflow

1. **Read the guide:**
   ```bash
   cat MIGRATION_GUIDE.md
   ```

2. **Backup your database** (see guide for instructions)

3. **Test in staging environment** (recommended)

4. **Run migration:**
   ```bash
   dart migrate_to_simplified_gamification.dart
   ```

5. **Verify migration:**
   ```bash
   dart verify_migration.dart
   ```

6. **Deploy updated app**

## Testing

Migration logic is tested in `test/migration/migration_test.dart`.

Run tests:
```bash
flutter test test/migration/migration_test.dart
```

## Support

For issues or questions:
- Review the MIGRATION_GUIDE.md
- Check test results in test/migration/migration_test.dart
- Consult the design document: .kiro/specs/simplified-gamification/design.md
- Review requirements: .kiro/specs/simplified-gamification/requirements.md

## Important Notes

- **Always backup before migration!**
- Test in a staging environment first
- Plan for a maintenance window
- Monitor the migration process
- Verify results before deploying the app
- Keep backup for at least 30 days after migration

## Related Files

- Design document: `.kiro/specs/simplified-gamification/design.md`
- Requirements: `.kiro/specs/simplified-gamification/requirements.md`
- Tasks: `.kiro/specs/simplified-gamification/tasks.md`
- Migration tests: `test/migration/migration_test.dart`
- User model: `lib/models/user_model.dart`
