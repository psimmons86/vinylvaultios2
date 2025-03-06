const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK with service account
const serviceAccountPath = path.join(__dirname, 'firebase-service-account.json');
if (!fs.existsSync(serviceAccountPath)) {
  console.error('❌ Firebase service account file not found!');
  console.error('Please copy the service account key file to this directory as firebase-service-account.json');
  process.exit(1);
}

console.log('Testing Firebase connection...');

try {
  // Initialize Firebase
  console.log('Initializing Firebase Admin SDK...');
  const serviceAccount = require(serviceAccountPath);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    // Explicitly disable App Check
    appCheck: {
      providerFactory: null,
      isTokenAutoRefreshEnabled: false
    }
  });
  console.log('✅ Firebase Admin SDK initialized successfully!');

  // Test Firestore connection
  async function testFirestore() {
    try {
      console.log('\nTesting Firestore connection...');
      const db = admin.firestore();
      
      // List collections
      const collections = await db.listCollections();
      console.log('Available Firestore collections:');
      
      if (collections.length === 0) {
        console.log('No collections found.');
      } else {
        for (const collection of collections) {
          const snapshot = await db.collection(collection.id).limit(1).get();
          console.log(`- ${collection.id} (${snapshot.size > 0 ? 'has documents' : 'empty'})`);
        }
      }
      
      // Test write operation
      console.log('\nTesting write operation...');
      const testRef = db.collection('_test_connection').doc('test_doc');
      await testRef.set({
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        message: 'Test connection successful'
      });
      console.log('✅ Write operation successful!');
      
      // Clean up test document
      await testRef.delete();
      console.log('Test document cleaned up');
      
      return true;
    } catch (error) {
      console.error('❌ Firestore test failed:', error);
      return false;
    }
  }

  // Test Storage connection
  async function testStorage() {
    try {
      console.log('\nTesting Storage connection...');
      
      // Use the provided bucket name
      const bucketName = 'vinylvault-c53cf.firebasestorage.app';
      console.log(`Using bucket: ${bucketName}`);
      
      const storage = admin.storage();
      const bucket = storage.bucket(bucketName);
      
      // List files (just checking connection)
      console.log('Checking Storage connection...');
      await bucket.getFiles({ maxResults: 1 });
      console.log('✅ Storage connection successful!');
      
      return true;
    } catch (error) {
      console.error('❌ Storage test failed:', error);
      return false;
    }
  }

  // Run tests
  (async () => {
    const firestoreSuccess = await testFirestore();
    const storageSuccess = await testStorage();
    
    console.log('\n--- Test Results ---');
    console.log(`Firestore: ${firestoreSuccess ? '✅ Connected' : '❌ Failed'}`);
    console.log(`Storage: ${storageSuccess ? '✅ Connected' : '❌ Failed'}`);
    
    // Exit
    process.exit(0);
  })();

} catch (error) {
  console.error('❌ Firebase initialization failed:', error);
  process.exit(1);
}
