# Firestore Indexes

This document explains the Firestore indexes required for the simplified gamification system.

## Index Configuration

The `firestore.indexes.json` file defines all composite indexes required for optimal query performance.

## Indexes Defined

### 1. Users Collection - Streak Points Index

**Purpose**: Enables efficient leaderboard queries sorted by streak points

**Fields**:
- `streakPoints` (DESCENDING)

**Used by**: Leaderboard screen to rank users by total streak points

### 2. Duels Collection - Challenger + Status Index

**Purpose**: Enables efficient queries for duels created by a specific user filtered by status

**Fields**:
- `challengerId` (ASCENDING)
- `status` (ASCENDING)

**Used by**: DuelService to fetch pending/active duels created by the user

### 3. Duels Collection - Opponent + Status Index

**Purpose**: Enables efficient queries for duels where a user is the opponent, filtered by status

**Fields**:
- `opponentId` (ASCENDING)
- `status` (ASCENDING)

**Used by**: DuelService to fetch pending/active duels where the user is challenged

### 4. Duels Collection - Status + Created Date Index

**Purpose**: Enables efficient queries for duels by status, sorted by creation date

**Fields**:
- `status` (ASCENDING)
- `createdAt` (DESCENDING)

**Used by**: DuelService for cleanup operations and displaying duels in chronological order

## Deploying Indexes

### Option 1: Firebase Console (Manual)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to Firestore Database → Indexes
4. Click "Add Index" for each index defined above
5. Configure the fields and sort orders as specified

### Option 2: Firebase CLI (Recommended)

1. Install Firebase CLI if not already installed:
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

4. Deploy the indexes:
   ```bash
   firebase deploy --only firestore:indexes
   ```

5. Monitor index build progress in the Firebase Console

## Index Build Time

- Indexes are built asynchronously by Firebase
- Build time depends on the amount of existing data in your collections
- For new collections: indexes build almost instantly
- For collections with existing data: may take several minutes to hours
- You can monitor build progress in the Firebase Console under Firestore → Indexes

## Testing Indexes

After deploying indexes, verify they're working:

1. Check the Firebase Console to ensure all indexes show "Enabled" status
2. Run queries that use these indexes in your app
3. Monitor Firestore usage in the console to ensure queries are efficient

## Troubleshooting

### Index Build Failures

If an index fails to build:
- Check the Firebase Console for error messages
- Ensure field names match exactly (case-sensitive)
- Verify you have sufficient permissions
- Try deleting and recreating the index

### Query Performance Issues

If queries are still slow after deploying indexes:
- Verify the index is in "Enabled" state (not "Building")
- Check that your query exactly matches the index fields and order
- Review the Firestore usage metrics in the console
- Consider adding additional indexes for specific query patterns

## Future Indexes

As the application evolves, you may need additional indexes for:
- Filtering duels by multiple criteria
- Sorting users by different metrics
- Complex queries involving multiple collections

Always test new queries in development and check the Firebase Console for index suggestions.
