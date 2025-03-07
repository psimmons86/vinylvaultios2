import SwiftUI
import Firebase

struct SimpleFriendsView: View {
    @State private var searchText = ""
    @State private var searchResults: [SimpleUser] = []
    @State private var friends: [SimpleUser] = []
    @State private var isSearching = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var activeTab = 0 // 0 = Friends, 1 = Search
    
    private let socialService = SimpleSocialService.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab selector
                    HStack(spacing: 0) {
                        tabButton(title: "Friends", index: 0)
                        tabButton(title: "Search", index: 1)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Content
                    TabView(selection: $activeTab) {
                        friendsTab
                            .tag(0)
                        
                        searchTab
                            .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.large)
            .alert("Error", isPresented: $showingError, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text(errorMessage ?? "An unknown error occurred")
            })
            .task {
                await loadFriends()
            }
            .refreshable {
                await loadFriends()
            }
        }
    }
    
    // MARK: - Tabs
    
    private var friendsTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                if isLoading {
                    ProgressView()
                        .padding()
                } else if friends.isEmpty {
                    emptyFriendsView
                } else {
                    ForEach(friends) { user in
                        friendCard(user: user)
                    }
                }
            }
            .padding()
        }
    }
    
    private var searchTab: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.textSecondary)
                
                TextField("Search by username or email", text: $searchText)
                    .font(AppFonts.bodyMedium)
                    .foregroundColor(AppColors.textPrimary)
                    .submitLabel(.search)
                    .onSubmit {
                        performSearch()
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        searchResults = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .padding()
            .background(AppColors.cardBackground)
            .cornerRadius(AppShapes.cornerRadiusMedium)
            .padding(.horizontal)
            .padding(.bottom)
            
            // Search results
            ScrollView {
                VStack(spacing: 16) {
                    if isSearching {
                        ProgressView()
                            .padding()
                    } else if !searchText.isEmpty && searchResults.isEmpty {
                        emptySearchResultsView
                    } else if !searchResults.isEmpty {
                        ForEach(searchResults) { user in
                            searchResultCard(user: user)
                        }
                    } else {
                        // Initial state
                        VStack(spacing: 16) {
                            Image(systemName: "person.fill.questionmark")
                                .font(.system(size: 60))
                                .foregroundColor(AppColors.textSecondary.opacity(0.5))
                                .padding(.bottom, 8)
                            
                            Text("Search for Friends")
                                .font(AppFonts.titleMedium)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Find other vinyl collectors by searching for their username or email")
                                .font(AppFonts.bodyMedium)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppColors.cardBackground)
                        .cornerRadius(AppShapes.cornerRadiusMedium)
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Empty States
    
    private var emptyFriendsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textSecondary.opacity(0.5))
                .padding(.bottom, 8)
            
            Text("No Friends Yet")
                .font(AppFonts.titleMedium)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Connect with other vinyl collectors by searching for them")
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                activeTab = 1 // Switch to search tab
            }) {
                Text("Find Friends")
                    .font(AppFonts.bodyLarge.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppColors.primary)
                    .cornerRadius(AppShapes.cornerRadiusMedium)
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppColors.cardBackground)
        .cornerRadius(AppShapes.cornerRadiusMedium)
    }
    
    private var emptySearchResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textSecondary.opacity(0.5))
                .padding(.bottom, 8)
            
            Text("No Results Found")
                .font(AppFonts.titleMedium)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Try searching with a different username or email")
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppColors.cardBackground)
        .cornerRadius(AppShapes.cornerRadiusMedium)
    }
    
    // MARK: - Cards
    
    private func friendCard(user: SimpleUser) -> some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Text(userInitials(for: user))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(AppFonts.bodyLarge.weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(user.email)
                    .font(AppFonts.bodySmall)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            // Remove button
            Button(action: {
                removeFriend(user: user)
            }) {
                Text("Remove")
                    .font(AppFonts.bodyMedium)
                    .foregroundColor(AppColors.error)
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(AppShapes.cornerRadiusMedium)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func searchResultCard(user: SimpleUser) -> some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Text(userInitials(for: user))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(AppFonts.bodyLarge.weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(user.email)
                    .font(AppFonts.bodySmall)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            // Add button
            if isFriend(user) {
                Text("Friend")
                    .font(AppFonts.bodyMedium)
                    .foregroundColor(AppColors.success)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppColors.success.opacity(0.1))
                    .cornerRadius(AppShapes.cornerRadiusSmall)
            } else {
                Button(action: {
                    addFriend(user: user)
                }) {
                    Text("Add")
                        .font(AppFonts.bodyMedium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppColors.primary)
                        .cornerRadius(AppShapes.cornerRadiusSmall)
                }
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(AppShapes.cornerRadiusMedium)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Helper Views
    
    private func tabButton(title: String, index: Int) -> some View {
        Button(action: {
            withAnimation {
                activeTab = index
            }
        }) {
            VStack(spacing: 8) {
                Text(title)
                    .font(AppFonts.bodyLarge.weight(activeTab == index ? .semibold : .regular))
                    .foregroundColor(activeTab == index ? AppColors.textPrimary : AppColors.textSecondary)
                    .padding(.vertical, 8)
                
                Rectangle()
                    .fill(activeTab == index ? AppColors.primary : Color.clear)
                    .frame(height: 3)
                    .cornerRadius(1.5)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Actions
    
    private func loadFriends() async {
        isLoading = true
        
        do {
            let result = try await withCheckedThrowingContinuation { continuation in
                socialService.fetchFriends { result in
                    continuation.resume(with: result)
                }
            }
            
            friends = result
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isLoading = false
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        searchResults = []
        
        Task {
            do {
                let result = try await withCheckedThrowingContinuation { continuation in
                    socialService.searchUsers(query: searchText) { result in
                        continuation.resume(with: result)
                    }
                }
                
                searchResults = result
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
            
            isSearching = false
        }
    }
    
    private func addFriend(user: SimpleUser) {
        Task {
            do {
                try await withCheckedThrowingContinuation { continuation in
                    socialService.addFriend(userId: user.id) { result in
                        continuation.resume(with: result)
                    }
                }
                
                // Update the friends list
                await loadFriends()
                
                // Update search results to reflect the new friend status
                searchResults = searchResults.map { $0.id == user.id ? user : $0 }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func removeFriend(user: SimpleUser) {
        Task {
            do {
                try await withCheckedThrowingContinuation { continuation in
                    socialService.removeFriend(userId: user.id) { result in
                        continuation.resume(with: result)
                    }
                }
                
                // Update the friends list
                await loadFriends()
                
                // Update search results to reflect the removed friend status
                searchResults = searchResults.map { $0.id == user.id ? user : $0 }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func userInitials(for user: SimpleUser) -> String {
        let name = user.username
        let components = name.components(separatedBy: " ")
        
        if components.count > 1, let first = components.first?.first, let last = components.last?.first {
            return "\(first)\(last)"
        } else if let first = name.first {
            return String(first)
        }
        
        return "U"
    }
    
    private func isFriend(_ user: SimpleUser) -> Bool {
        return friends.contains { $0.id == user.id }
    }
}

struct SimpleFriendsView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleFriendsView()
    }
}
