import SwiftUI
import FirebaseCore

@main
struct VinylVaultApp: App {
    @StateObject private var recordStore = RecordStore()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Create a shared DiscogsServiceWrapper instance
    @StateObject private var discogsService = DiscogsServiceWrapper(token: "uHdTAYXRutwEauUglilK:NxEMySZdVbSICratWgfNbLpZaEayoZMU")
    private let firebaseService = FirebaseService.shared
    
    // State for authentication
    @State private var isLoggedIn = false
    
    init() {
        // Configure Firebase Service
        firebaseService.configure()
        
        // Apply custom appearance
        configureAppAppearance()
        
        #if DEBUG
        print("🎵 VinylVault initialized with Discogs API and Firebase")
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                MainTabView(discogsService: discogsService)
                    .environmentObject(recordStore)
                    .onAppear {
                        #if DEBUG
                        print("🚀 App launched with RecordStore count: \(recordStore.records.count)")
                        #endif
                    }
            } else {
                LoginView(discogsService: discogsService, isLoggedIn: $isLoggedIn)
                    .environmentObject(recordStore)
            }
        }
    }
    
    private func configureAppAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColors.background)
        appearance.titleTextAttributes = [.foregroundColor: UIColor(AppColors.textPrimary)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(AppColors.textPrimary)]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(AppColors.background)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}

struct MainTabView: View {
    let discogsService: DiscogsServiceWrapper
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CollectionView()
                .tabItem {
                    Label("Collection", systemImage: "music.note.list")
                }
                .tag(0)
            
            SearchView(discogsService: discogsService)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)
            
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(2)
            
            SimpleProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .accentColor(AppColors.primary)
    }
}
