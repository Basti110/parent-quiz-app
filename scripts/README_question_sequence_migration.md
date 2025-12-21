# Question Sequence Migration

This directory contains scripts for migrating existing questions to support the new question pool architecture.

## Overview

The question pool architecture requires a `sequence` field on all questions for deterministic pagination. This migration adds:

- **`sequence`**: Monotonically increasing integer (1, 2, 3, ...) based on `createdAt` order
- **`randomSeed`**: Random double [0.0, 1.0] for pool randomization (if missing)

## Scripts

### 1. Migration Script

**File**: `migrate_questions_add_sequence.dart`

Adds sequence numbers to all existing questions:

```bash
dart scripts/migrate_questions_add_sequence.dart
```

**What it does**:
- Loads all questions ordered by `createdAt`
- Assigns consecutive sequence numbers starting from 1
- Adds `randomSeed` field if missing
- Processes in batches of 500 to avoid timeouts
- Includes verification step

**Safety features**:
- Batch processing to avoid Firestore limits
- Automatic verification after migration
- Detailed progress logging
- Error handling and rollback safety

### 2. Verification Script

**File**: `verify_question_sequence_migration.dart`

Verifies the migration was successful:

```bash
dart scripts/verify_question_sequence_migration.dart
```

**What it checks**:
- All questions have `sequence` field
- All sequences are unique
- Sequences are consecutive (1, 2, 3, ...)
- All questions have `randomSeed` field
- Sample data validation

## Migration Process

### Prerequisites

1. **Backup your data** before running migration
2. Ensure Firebase is properly configured
3. Test on a development environment first

### Step-by-Step Process

1. **Run Migration**:
   ```bash
   dart scripts/migrate_questions_add_sequence.dart
   ```

2. **Verify Results**:
   ```bash
   dart scripts/verify_question_sequence_migration.dart
   ```

3. **Check Output**:
   - Migration should show "✅ Migration completed successfully!"
   - Verification should show "✅ All verifications passed!"

### Expected Output

**Migration Success**:
```
🚀 Starting question sequence migration...
📊 Loading existing questions...
📝 Found 1250 questions to migrate
🔄 Processing batch 1/3 (questions 1-500)
✅ Batch completed. Processed 500/1250 questions
🔄 Processing batch 2/3 (questions 501-1000)
✅ Batch completed. Processed 1000/1250 questions
🔄 Processing batch 3/3 (questions 1001-1250)
✅ Batch completed. Processed 1250/1250 questions
🎉 Successfully migrated 1250 questions with sequence numbers 1-1250
🔍 Verifying migration...
✅ Verification successful: 1250/1250 questions have sequence field
✅ No duplicate sequences found
📈 Sequence range: 1 - 1250
✅ Migration completed successfully!
```

**Verification Success**:
```
🔍 Starting question sequence migration verification...
📊 Loading all questions...
📝 Found 1250 questions

🧪 Test 1: Checking sequence field presence...
✅ All 1250 questions have sequence field

🧪 Test 2: Checking for duplicate sequences...
✅ No duplicate sequences found

🧪 Test 3: Checking sequence range and consecutiveness...
📈 Sequence range: 1 - 1250
✅ Sequences start from 1
✅ Sequences are consecutive (1 to 1250)
✅ No gaps in sequence

🧪 Test 4: Checking randomSeed field presence...
✅ All 1250 questions have randomSeed field

🧪 Test 5: Sample data validation...
📋 Sample question data:
   ID: abc123
   sequence: 1
   randomSeed: 0.7234567
   categoryId: category1
   difficulty: medium
   isActive: true
✅ Sample randomSeed is in valid range [0.0, 1.0]

📊 Migration Verification Summary:
   Total questions: 1250
   Questions with sequence: 1250
   Questions with randomSeed: 1250
   Unique sequences: 1250
✅ All verifications passed!
```

## Troubleshooting

### Common Issues

1. **Firebase Connection Error**:
   - Ensure Firebase is properly initialized
   - Check network connectivity
   - Verify Firebase project configuration

2. **Permission Errors**:
   - Ensure service account has write permissions
   - Check Firestore security rules

3. **Timeout Errors**:
   - Script uses batching to avoid timeouts
   - If still occurring, reduce batch size in script

4. **Duplicate Sequences**:
   - Should not happen with this script
   - If found, re-run migration (it's idempotent)

### Recovery

If migration fails partway through:

1. **Check current state**:
   ```bash
   dart scripts/verify_question_sequence_migration.dart
   ```

2. **Re-run migration**:
   - Script is designed to be idempotent
   - Will skip questions that already have sequence numbers
   - Safe to run multiple times

3. **Manual cleanup** (if needed):
   - Use Firebase Console to inspect data
   - Remove sequence fields and re-run if necessary

## Performance Considerations

- **Batch Size**: 500 questions per batch (Firestore limit)
- **Processing Time**: ~1-2 seconds per 100 questions
- **Memory Usage**: Minimal (processes in batches)
- **Network**: One read + multiple batch writes

## Post-Migration

After successful migration:

1. **Update Firestore Indexes**:
   - Add indexes for sequence-based queries
   - See `firestore.indexes.json` in project root

2. **Deploy New Code**:
   - Deploy question pool architecture code
   - Enable feature flags gradually

3. **Monitor Performance**:
   - Watch query performance
   - Monitor pool expansion metrics

## Rollback Plan

If you need to rollback:

1. **Remove new fields**:
   ```javascript
   // Firestore Console or script
   questions.forEach(doc => {
     doc.update({
       sequence: FieldValue.delete(),
       randomSeed: FieldValue.delete() // only if added by migration
     });
   });
   ```

2. **Revert code deployment**
3. **Remove new indexes**

## Testing

Test the migration on a development environment:

1. Copy production data to dev environment
2. Run migration scripts
3. Test question pool functionality
4. Verify performance improvements
5. Only then run on production