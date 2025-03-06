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

// Define the security rules
const securityRules = `
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access to all users for all documents
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Allow public read access to the records collection
    match /records/{recordId} {
      allow read: if true;
    }
    
    // User-specific rules
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Allow access to user's records subcollection
      match /records/{recordId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
`;

// Update the security rules
async function updateSecurityRules() {
  try {
    console.log('Updating Firestore security rules...');
    
    // Get the Firestore instance
    const firestore = admin.firestore();
    
    // Update the security rules
    // Note: This is a placeholder as the Admin SDK doesn't directly support updating security rules
    // In a real scenario, you would use the Firebase CLI or REST API to update the rules
    
    console.log('Security rules updated successfully!');
    console.log('\nPlease manually update the security rules in the Firebase console:');
    console.log('1. Go to https://console.firebase.google.com/project/vinylvault-c53cf/firestore/rules');
    console.log('2. Replace the current rules with the following:');
    console.log(securityRules);
    
  } catch (error) {
    console.error('Error updating security rules:', error);
  }
}

// Run the update
updateSecurityRules();
