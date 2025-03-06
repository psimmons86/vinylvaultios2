# MongoDB to Firebase Migration

This guide provides instructions for migrating data from MongoDB to Firebase Firestore.

## Prerequisites

1. Node.js installed (v14 or later recommended)
2. Firebase service account key file
3. MongoDB connection URI and database name

## Setup

1. **Firebase Service Account Key**:
   - Download from Firebase Console > Project Settings > Service Accounts
   - Save as `firebase-service-account.json` in this directory

2. **MongoDB Connection**:
   - You need a MongoDB connection URI
   - The default database name is set to "vinyl-vault"

## Running the Migration

### Option 1: Using the Automated Script

Run the automated migration script:

```bash
./run-migration.sh
```

This script will:
1. Copy your Firebase service account key from Downloads
2. Set up MongoDB connection environment variables
3. Install required dependencies
4. Test connections to both MongoDB and Firebase
5. Run the migration if tests pass

### Option 2: Manual Steps

If you prefer to run the steps manually:

1. Install dependencies:
   ```bash
   npm install
   ```

2. Test MongoDB connection:
   ```bash
   node test-mongodb-connection.js
   ```

3. Test Firebase connection:
   ```bash
   node test-firebase-connection.js
   ```

4. Run the migration:
   ```bash
   node mongodb-to-firebase.js
   ```

## Troubleshooting

### MongoDB Connection Issues

- **Error**: "Connection failed: MongoServerSelectionError: connection <monitor> to <host> closed"
  - **Solution**: Check your MongoDB URI, ensure the database is running and accessible

- **Error**: "Authentication failed"
  - **Solution**: Verify your MongoDB username and password in the connection URI

### Firebase Connection Issues

- **Error**: "Firebase initialization failed: Error: Failed to parse private key"
  - **Solution**: Ensure your service account key file is valid and properly formatted

- **Error**: "Storage test failed: Error: Missing required storage bucket"
  - **Solution**: Verify the storage bucket name in the test-firebase-connection.js file

- **Error**: "App Check API has not been used in project"
  - **Solution**: We've disabled App Check in the migration scripts. If you want to enable it:
    1. Go to https://console.developers.google.com/apis/api/firebaseappcheck.googleapis.com/overview?project=413544524500
    2. Click "Enable API"
    3. Wait a few minutes for the change to propagate

## Data Migration Details

The migration process:

1. Connects to MongoDB and retrieves all documents from specified collections
2. Transforms MongoDB documents to Firestore format:
   - Converts MongoDB _id fields to Firestore document IDs
   - Converts Date objects to Firestore Timestamps
   - Preserves nested objects and arrays
3. Writes data to Firestore in batches (to avoid Firestore limits)

## Collection Mapping

By default, the script migrates the following collections:
- MongoDB "users" → Firestore "users"
- MongoDB "records" → Firestore "records"

To modify which collections are migrated, edit the `collectionMapping` object in the `mongodb-to-firebase.js` file.
