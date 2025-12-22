# Firestore Indexes

This document explains the Firestore indexes required for the question pool architecture and other app features.

## Index Configuration

The indexes are defined in `firestore.indexes.json` and are automatically deployed with Firebase CLI.

## Question Pool Architecture Indexes

### QuestionStates Collection Indexes

The question pool architecture requires several composite indexes for the `questionStates` subcollection to support efficient querying:

#### 1. Basic Pool Queries
- **Fields**: `mastered (ASC)`, `seenCount (ASC)`, `randomSeed (ASC)`
- **Purpose**: Three-tier priority selection (unseen → unmastered → mastered)
- **Query**: Select questions by mastery status and seen count for randomization

#### 2. Category-Filtered Queries
- **Fields**: `categoryId (ASC)`, `mastered (ASC)`, `seenCount (ASC)`
- **Purpose**: Filter questions by specific category during selection
- **Query**: Get questions from a specific category with priority ordering

#### 3. Difficulty-Filtered Queries
- **Fields**: `difficulty (ASC)`, `mastered (ASC)`, `seenCount (ASC)`
- **Purpose**: Filter questions by difficulty level during selection
- **Query**: Get questions of specific difficulty with priority ordering

#### 4. Combined Filter Queries
- **Fields**: `categoryId (ASC)`, `difficulty (ASC)`, `mastered (ASC)`, `seenCount (ASC)`
- **Purpose**: Filter by both category and difficulty simultaneously
- **Query**: Most specific filtering for targeted question selection

#### 5. Counting Indexes
Additional indexes for efficient counting operations:
- **Unseen Count**: `seenCount (ASC)` - Count questions with seenCount = 0
- **Mastery Count**: `mastered (ASC)` - Count mastered vs unmastered questions
- **Category Counts**: Various combinations with `categoryId` for per-category statistics
- **Difficulty Counts**: Various combinations with `difficulty` for difficulty-based statistics

#### 6. Duplicate Prevention
- **Fields**: `questionId (ASC)`
- **Purpose**: Efficiently check for existing question states during pool expansion
- **Query**: Batch queries using `whereIn` to prevent duplicate state creation

### Questions Collection Indexes

The global questions collection requires indexes for efficient pool expansion:

#### 1. Sequence-Based Expansion
- **Fields**: `isActive (ASC)`, `sequence (ASC)`
- **Purpose**: Load questions in batches using sequence-based pagination
- **Query**: Get next batch of active questions after a specific sequence number

#### 2. Category-Filtered Expansion
- **Fields**: `categoryId (ASC)`, `isActive (ASC)`, `sequence (ASC)`
- **Purpose**: Load questions from specific category during expansion
- **Query**: Batch loading with category filter

#### 3. Difficulty-Filtered Expansion
- **Fields**: `difficulty (ASC)`, `isActive (ASC)`, `sequence (ASC)`
- **Purpose**: Load questions of specific difficulty during expansion
- **Query**: Batch loading with difficulty filter

#### 4. Combined Filter Expansion
- **Fields**: `categoryId (ASC)`, `difficulty (ASC)`, `isActive (ASC)`, `sequence (ASC)`
- **Purpose**: Most specific expansion queries with both filters
- **Query**: Targeted batch loading for specific category and difficulty

## Existing App Indexes

### User Leaderboard
- **Fields**: `streakPoints (DESC)`
- **Purpose**: Leaderboard ranking by streak points
- **Collection**: `users`

### Duel System
Multiple indexes for the asynchronous duel system:

#### 1. Challenger's Duels
- **Fields**: `challengerId (ASC)`, `status (ASC)`
- **Purpose**: Find duels created by a specific user
- **Collection**: `duels`

#### 2. Opponent's Duels
- **Fields**: `opponentId (ASC)`, `status (ASC)`
- **Purpose**: Find duels where user is the opponent
- **Collection**: `duels`

#### 3. Duel Cleanup
- **Fields**: `status (ASC)`, `createdAt (DESC)`
- **Purpose**: Find expired duels for cleanup operations
- **Collection**: `duels`

## Performance Considerations

### Query Optimization
1. **Limit Results**: All queries use `.limit()` to prevent excessive data loading
2. **Composite Indexes**: Every filter combination has a dedicated composite index
3. **Batch Operations**: Pool expansion uses batch writes for efficiency
4. **Pagination**: Sequence-based pagination for scalable pool expansion

### Index Efficiency
1. **Selective Fields**: Indexes include only necessary fields for each query pattern
2. **Proper Ordering**: Field order optimized for query selectivity
3. **Minimal Redundancy**: Indexes cover multiple related query patterns where possible

### Monitoring
Track these metrics for index performance:
- Query execution time (should be < 100ms for pool queries)
- Index usage statistics in Firebase Console
- Pool expansion batch timing
- Question selection latency

## Deployment

### Firebase CLI Deployment
```bash
# Deploy indexes (takes time to build in production)
firebase deploy --only firestore:indexes

# Check index build status
firebase firestore:indexes
```

### Index Build Time
- **Development**: Indexes build quickly with small datasets
- **Production**: Large collections may take hours to build new indexes
- **Strategy**: Deploy indexes before deploying code that uses them

### Rollback Strategy
If new indexes cause issues:
1. Keep old indexes active during transition
2. Monitor query performance after deployment
3. Remove old indexes only after confirming new ones work
4. Have rollback plan for code changes

## Testing Index Performance

### Local Testing
```bash
# Start Firestore emulator with indexes
firebase emulators:start --only firestore

# Run tests that exercise the queries
flutter test test/services/question_pool_service_test.dart
```

### Production Monitoring
1. **Firebase Console**: Monitor query performance and index usage
2. **Application Logs**: Track query execution times
3. **User Experience**: Monitor app responsiveness during pool operations
4. **Alerts**: Set up alerts for slow queries (> 2 seconds)

## Index Maintenance

### Regular Reviews
- **Monthly**: Review index usage statistics
- **Quarterly**: Analyze query patterns for optimization opportunities
- **After Features**: Update indexes when adding new query patterns

### Cleanup
- Remove unused indexes to reduce storage costs
- Consolidate overlapping indexes where possible
- Monitor for queries that don't use indexes (appear in Firebase Console warnings)

## Troubleshooting

### Common Issues
1. **Missing Index Error**: Add the exact index shown in Firebase Console error
2. **Slow Queries**: Check if queries are using the expected indexes
3. **Index Build Failures**: Verify field names and types match the schema
4. **Query Limits**: Ensure queries don't exceed Firestore limits (e.g., 'in' queries limited to 10 values)

### Debug Steps
1. Check Firebase Console for index build status
2. Verify query structure matches index field order
3. Test queries in Firestore Console
4. Review application logs for query performance
5. Use Firebase Performance Monitoring for detailed metrics