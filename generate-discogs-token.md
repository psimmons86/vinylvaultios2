# Generating a New Discogs API Token

The current Discogs API token in your app is invalid or expired. Follow these steps to generate a new token:

## Step 1: Create a Discogs Account (if you don't have one)
1. Go to https://www.discogs.com/
2. Click "Register" in the top right corner
3. Follow the registration process

## Step 2: Create a New Application
1. Go to https://www.discogs.com/settings/developers
2. Click "Create an Application"
3. Fill in the application details:
   - Application name: VinylVault
   - Description: A personal vinyl record collection app
   - Website: (leave blank or put your website)
   - Callback URL: (leave blank)

## Step 3: Get Your Personal Access Token
1. After creating the application, you'll see your application details
2. Look for "Personal access token" - this is what you need
3. Copy this token

## Step 4: Update Your App
1. Open VinylVaultApp.swift
2. Replace the existing token with your new token:

```swift
@StateObject private var discogsService = DiscogsServiceWrapper(token: "YOUR_NEW_TOKEN_HERE")
```

## Testing Your Token
You can test your token with the test-discogs-api.js script:
1. Update the token in the script
2. Run `node test-discogs-api.js`
3. If successful, you should see search results

## Important Notes
- Keep your token secure - don't share it publicly
- Discogs API has rate limits (60 requests per minute)
- For production apps, consider using OAuth instead of personal tokens
