# VinylVault

A SwiftUI iOS app for cataloging your vinyl record collection using the Discogs API and Firebase.

## Features

- Search the Discogs database for vinyl records
- Add records to your collection
- View detailed record information
- Track play count and last played date
- Add tags and notes to records
- View collection statistics
- Filter and sort your collection
- Mark records as "in heavy rotation"
- User authentication with Firebase
- Cloud storage for your collection

## Requirements

- iOS 16.0+
- Xcode 14.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- Discogs API credentials
- Firebase project

## Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd VinylVault
```

2. Get Discogs API Credentials:
- Go to [Discogs Developers](https://www.discogs.com/settings/developers)
- Create a new application
- Note down your Consumer Key and Consumer Secret

3. Set up Firebase:
- Go to the [Firebase Console](https://console.firebase.google.com/)
- Create a new project or use an existing one
- Add an iOS app to your Firebase project
- Download the GoogleService-Info.plist file
- Replace the placeholder file in the project with the downloaded one

4. Generate Xcode project:
```bash
xcodegen generate
```

5. Open the project:
```bash
open VinylVault.xcodeproj
```

6. Build and run the app in Xcode

## Project Structure

```
VinylVault/
├── Models/
│   └── Record.swift
├── Views/
│   ├── CollectionView.swift
│   ├── SearchView.swift
│   ├── RecordDetailView.swift
│   ├── RecordRowView.swift
│   └── LoginView.swift
├── Services/
│   ├── DiscogsService.swift
│   ├── RecordStore.swift
│   └── FirebaseService.swift
├── VinylVaultApp.swift
└── AppDelegate.swift
```

## Architecture

- SwiftUI for the UI layer
- MVVM architecture
- Firebase for authentication and cloud storage
- UserDefaults for local caching
- Async/await for API calls
- Environment objects for dependency injection

## Firebase Integration

The app uses several Firebase services:
- **Firebase Authentication**: For user sign-up and sign-in
- **Cloud Firestore**: For storing record collections in the cloud
- **Firebase Storage**: For storing record images
- **Firebase App Check**: For securing your Firebase resources

## Features to Add

- [ ] Barcode scanning for quick record lookup
- [ ] Export collection data
- [ ] Record condition tracking
- [ ] Collection value tracking
- [ ] Wishlist management
- [ ] Social features (share collection, follow other collectors)
- [ ] Integration with music streaming services

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Discogs API](https://www.discogs.com/developers) for providing record data
- [Firebase](https://firebase.google.com/) for authentication and cloud storage
- [SwiftUI](https://developer.apple.com/xcode/swiftui/) for the UI framework
