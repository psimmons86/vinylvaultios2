import SwiftUI
import FirebaseCore

@main
struct VinylVaultApp: App {
    @StateObject private var recordStore = RecordStore()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Create a shared DiscogsServiceWrapper instance
    @StateObject private var discogsService = DiscogsServiceWrapper(token: "uHdTAYXRutwEauUglilK:NxEMySZdVbSICratWgfNbLpZaEayoZMU")
    private let firebaseService = FirebaseService.shared
    
    init() {
        // Configure Firebase Service
        firebaseService.configure()
        
        #if DEBUG
        print("🎵 VinylVault initialized with Discogs API and Firebase")
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            LoginView(discogsService: discogsService)
                .environmentObject(recordStore)
                .onAppear {
                    #if DEBUG
                    print("🚀 App launched with RecordStore count: \(recordStore.records.count)")
                    #endif
                }
        }
    }
}
