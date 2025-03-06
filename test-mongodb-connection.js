const { MongoClient } = require('mongodb');

// MongoDB connection settings
const mongoUri = "mongodb+srv://admin:cY8zCS8Sp37HGVvx@student-cluster.xmbxi.mongodb.net/music-dashboard?retryWrites=true&w=majority&appName=student-cluster";
const mongoDbName = "music-dashboard";

async function testConnection() {
  console.log('Testing MongoDB connection...');
  
  try {
    // Connect to MongoDB
    console.log(`Connecting to MongoDB at ${mongoUri}...`);
    const client = new MongoClient(mongoUri);
    await client.connect();
    console.log('✅ Successfully connected to MongoDB!');
    
    // Get database and list collections
    const db = client.db(mongoDbName);
    const collections = await db.listCollections().toArray();
    
    console.log(`\nAvailable collections in ${mongoDbName}:`);
    if (collections.length === 0) {
      console.log('No collections found.');
    } else {
      for (const collection of collections) {
        const count = await db.collection(collection.name).countDocuments();
        console.log(`- ${collection.name} (${count} documents)`);
      }
    }
    
    // Close MongoDB connection
    await client.close();
    console.log('\nMongoDB connection closed');
    
  } catch (error) {
    console.error('❌ Connection failed:', error);
  }
}

// Run the test
testConnection();
