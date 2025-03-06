const { MongoClient } = require('mongodb');
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK with service account
const serviceAccountPath = path.join(__dirname, 'firebase-service-account.json');
if (!fs.existsSync(serviceAccountPath)) {
  console.error('Firebase service account file not found!');
  console.error('Please download your service account key from Firebase console:');
  console.error('1. Go to Firebase console > Project settings > Service accounts');
  console.error('2. Click "Generate new private key"');
  console.error('3. Save the file as "firebase-service-account.json" in the same directory as this script');
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  // Explicitly disable App Check
  appCheck: {
    providerFactory: null,
    isTokenAutoRefreshEnabled: false
  },
  // Set the correct storage bucket
  storageBucket: 'vinylvault-c53cf.firebasestorage.app'
});

const db = admin.firestore();

// MongoDB connection settings
const mongoUri = process.env.MONGO_URI || 'mongodb://localhost:27017';
const mongoDbName = process.env.MONGO_DB_NAME || 'music-dashboard';

// Collection mapping (MongoDB collection name -> Firestore collection name)
const collectionMapping = {
  'users': 'users',
  'vinyls': 'records',
  'weeklyplaylists': 'weeklyplaylists',
  'posts': 'posts',
  'blogs': 'blogs',
  'articles': 'articles'
};

// Log the collections we're going to migrate
console.log('Collections to migrate:');
for (const [mongoCollection, firestoreCollection] of Object.entries(collectionMapping)) {
  console.log(`- ${mongoCollection} -> ${firestoreCollection}`);
}

async function migrateCollection(mongoDb, collectionName, firestoreCollectionName) {
  console.log(`Migrating collection: ${collectionName} -> ${firestoreCollectionName}`);
  
  const collection = mongoDb.collection(collectionName);
  const documents = await collection.find({}).toArray();
  
  console.log(`Found ${documents.length} documents in ${collectionName}`);
  
  // Process in batches to avoid Firestore limits
  const batchSize = 500;
  const batches = [];
  
  for (let i = 0; i < documents.length; i += batchSize) {
    batches.push(documents.slice(i, i + batchSize));
  }
  
  for (let [batchIndex, batch] of batches.entries()) {
    console.log(`Processing batch ${batchIndex + 1}/${batches.length}`);
    
    const firestoreBatch = db.batch();
    
    for (const doc of batch) {
      // Convert MongoDB _id to string for Firestore
      const docId = doc._id.toString();
      delete doc._id;
      
      // Transform MongoDB document to Firestore format
      const firestoreDoc = transformDocument(doc);
      
      // Add to batch
      const docRef = db.collection(firestoreCollectionName).doc(docId);
      firestoreBatch.set(docRef, firestoreDoc);
    }
    
    // Commit the batch
    await firestoreBatch.commit();
    console.log(`Batch ${batchIndex + 1} committed successfully`);
  }
  
  console.log(`Migration of ${collectionName} completed`);
}

// Transform MongoDB document to Firestore format
function transformDocument(doc) {
  const result = {};
  
  // Handle MongoDB specific types
  for (const [key, value] of Object.entries(doc)) {
    if (value instanceof Date) {
      // Convert Date to Firestore Timestamp
      result[key] = admin.firestore.Timestamp.fromDate(value);
    } else if (Array.isArray(value)) {
      // Handle arrays
      result[key] = value.map(item => {
        if (typeof item === 'object' && item !== null) {
          return transformDocument(item);
        }
        return item;
      });
    } else if (typeof value === 'object' && value !== null) {
      // Handle nested objects
      result[key] = transformDocument(value);
    } else {
      // Handle primitive values
      result[key] = value;
    }
  }
  
  return result;
}

// Main migration function
async function migrateData() {
  console.log('Starting MongoDB to Firebase migration...');
  
  try {
    // Connect to MongoDB
    console.log(`Connecting to MongoDB at ${mongoUri}...`);
    const client = new MongoClient(mongoUri);
    await client.connect();
    console.log('Connected to MongoDB');
    
    const mongoDb = client.db(mongoDbName);
    
    // Migrate each collection
    for (const [mongoCollection, firestoreCollection] of Object.entries(collectionMapping)) {
      await migrateCollection(mongoDb, mongoCollection, firestoreCollection);
    }
    
    // Close MongoDB connection
    await client.close();
    console.log('MongoDB connection closed');
    
    console.log('Migration completed successfully!');
  } catch (error) {
    console.error('Migration failed:', error);
  }
}

// Run the migration
migrateData();
