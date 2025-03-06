#!/bin/bash

# Copy Firebase service account key from downloads folder
echo "Copying Firebase service account key..."
cp ~/Downloads/vinylvault-c53cf-firebase-adminsdk-fbsvc-dfaa6f2790.json ./firebase-service-account.json
if [ $? -eq 0 ]; then
  echo "✅ Firebase service account key copied successfully"
else
  echo "❌ Failed to copy Firebase service account key"
  echo "Please manually copy the file to this directory and rename it to firebase-service-account.json"
  exit 1
fi

# Set MongoDB environment variables
export MONGO_URI="mongodb+srv://admin:cY8zCS8Sp37HGVvx@student-cluster.xmbxi.mongodb.net/music-dashboard?retryWrites=true&w=majority&appName=student-cluster"
export MONGO_DB_NAME="music-dashboard"

# Install dependencies
echo "Installing dependencies..."
npm install
if [ $? -eq 0 ]; then
  echo "✅ Dependencies installed successfully"
else
  echo "❌ Failed to install dependencies"
  exit 1
fi

# Test MongoDB connection
echo -e "\n=== Testing MongoDB Connection ==="
node test-mongodb-connection.js
if [ $? -ne 0 ]; then
  echo "❌ MongoDB connection test failed. Please check your MongoDB URI and credentials."
  exit 1
fi

# Test Firebase connection
echo -e "\n=== Testing Firebase Connection ==="
node test-firebase-connection.js
if [ $? -ne 0 ]; then
  echo "❌ Firebase connection test failed. Please check your Firebase service account key."
  exit 1
fi

# Prompt user to continue
echo -e "\nDo you want to proceed with the migration? (y/n)"
read -r proceed
if [[ ! $proceed =~ ^[Yy]$ ]]; then
  echo "Migration cancelled by user."
  exit 0
fi

# Run migration script
echo -e "\n=== Starting Migration ==="
node mongodb-to-firebase.js

# Clean up
echo -e "\n=== Cleanup ==="
echo "Note: The firebase-service-account.json file has been kept for future migrations."
echo "If you want to remove it for security reasons, run: rm firebase-service-account.json"
