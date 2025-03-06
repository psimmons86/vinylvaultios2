const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK with service account
const serviceAccountPath = path.join(__dirname, 'firebase-service-account.json');
if (!fs.existsSync(serviceAccountPath)) {
  console.error('Firebase service account file not found!');
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'vinylvault-c53cf.firebasestorage.app'
});

const db = admin.firestore();

async function checkFirestore() {
  console.log('Checking Firestore collections...');
  
  try {
    // Get all collections
    const collections = await db.listCollections();
    
    if (collections.length === 0) {
      console.log('No collections found in Firestore.');
      return;
    }
    
    console.log(`Found ${collections.length} collections in Firestore:`);
    
    // Check each collection
    for (const collection of collections) {
      const snapshot = await db.collection(collection.id).get();
      console.log(`- ${collection.id}: ${snapshot.size} documents`);
    }
    
    // Look for user with username psimmons86
    console.log('\nLooking for user with username "psimmons86"...');
    const usersSnapshot = await db.collection('users').get();
    let foundUser = null;
    
    for (const doc of usersSnapshot.docs) {
      const userData = doc.data();
      if (userData.username === 'psimmons86') {
        foundUser = userData;
        console.log('Found user with username "psimmons86":');
        console.log(JSON.stringify(userData, null, 2));
        break;
      }
    }
    
    if (!foundUser) {
      console.log('User with username "psimmons86" not found.');
      
      // List all users
      console.log('\nListing all users:');
      for (const doc of usersSnapshot.docs) {
        const userData = doc.data();
        console.log(`- Username: ${userData.username || 'N/A'}, Email: ${userData.email || 'N/A'}`);
      }
    }
    
    // Check record structure
    console.log('\nChecking record structure...');
    const recordsSnapshot = await db.collection('records').limit(1).get();
    
    if (recordsSnapshot.size > 0) {
      const sampleRecord = recordsSnapshot.docs[0].data();
      console.log('Sample record structure:');
      console.log(JSON.stringify(sampleRecord, null, 2));
      
      // Check what fields are available to link to users
      console.log('\nFields that might link to users:');
      for (const key in sampleRecord) {
        if (typeof sampleRecord[key] === 'object' && sampleRecord[key] !== null) {
          console.log(`- ${key}: ${JSON.stringify(sampleRecord[key])}`);
        } else if (key.toLowerCase().includes('user')) {
          console.log(`- ${key}: ${sampleRecord[key]}`);
        }
      }
    } else {
      console.log('No records found.');
    }
    
  } catch (error) {
    console.error('Error checking Firestore:', error);
  }
}

// Run the check
checkFirestore();
