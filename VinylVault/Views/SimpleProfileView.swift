import SwiftUI
import FirebaseAuth
import PhotosUI

struct SimpleProfileView: View {
    @State private var user: SimpleUser?
    @State private var showingSignOutConfirmation = false
    @State private var isLoading = false
    @State private var profileImage: UIImage?
    @State private var showingImagePicker = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var errorMessage: String?
    @State private var showingError = false
    
    private let socialService = SimpleSocialService.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // User Info Section
                        userInfoSection
                        
                        // Settings Section
                        settingsSection
                        
                        // Sign Out Button
                        signOutButton
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .alert("Error", isPresented: $showingError, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text(errorMessage ?? "An unknown error occurred")
            })
            .alert(isPresented: $showingSignOutConfirmation) {
                Alert(
                    title: Text("Sign Out"),
                    message: Text("Are you sure you want to sign out?"),
                    primaryButton: .destructive(Text("Sign Out")) {
                        signOut()
                    },
                    secondaryButton: .cancel()
                )
            }
            .task {
                loadUserProfile()
            }
        }
    }
    
    // MARK: - View Components
    
    private var userInfoSection: some View {
        VStack(spacing: 20) {
            // User Avatar
            ZStack {
                if let profileImage = profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(AppColors.cardBackground, lineWidth: 3)
                        )
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.primary, AppColors.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Text(userInitials)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                // Edit button
                Button(action: {
                    showingImagePicker = true
                }) {
                    ZStack {
                        Circle()
                            .fill(AppColors.primary)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                }
                .offset(x: 35, y: 35)
            }
            
            // User Name and Email
            VStack(spacing: 4) {
                Text(userName)
                    .font(AppFonts.titleMedium)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(userEmail)
                    .font(AppFonts.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppColors.cardBackground)
        .cornerRadius(AppShapes.cornerRadiusMedium)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
        .photosPicker(isPresented: $showingImagePicker, selection: $photoPickerItem, matching: .images)
        .onChange(of: photoPickerItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    profileImage = uiImage
                    uploadProfileImage(data)
                }
            }
        }
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(AppFonts.titleSmall)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                NavigationLink(destination: SimpleFriendsView()) {
                    settingsRowContent(title: "Friends", icon: "person.2.fill", color: AppColors.primary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .padding(.leading, 50)
                
                settingsRow(title: "Notifications", icon: "bell.fill", color: AppColors.accent1)
                
                Divider()
                    .padding(.leading, 50)
                
                settingsRow(title: "Appearance", icon: "paintbrush.fill", color: AppColors.accent3)
                
                Divider()
                    .padding(.leading, 50)
                
                settingsRow(title: "Privacy", icon: "lock.fill", color: AppColors.secondary)
                
                Divider()
                    .padding(.leading, 50)
                
                settingsRow(title: "Help & Support", icon: "questionmark.circle.fill", color: AppColors.tertiary)
            }
            .background(AppColors.cardBackground)
            .cornerRadius(AppShapes.cornerRadiusMedium)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            .padding(.horizontal)
        }
    }
    
    private func settingsRow(title: String, icon: String, color: Color) -> some View {
        Button(action: {
            // Settings action would go here
        }) {
            settingsRowContent(title: title, icon: icon, color: color)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func settingsRowContent(title: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .font(AppFonts.bodyLarge)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding()
    }
    
    private var signOutButton: some View {
        Button(action: {
            showingSignOutConfirmation = true
        }) {
            HStack {
                Spacer()
                
                Text("Sign Out")
                    .font(AppFonts.bodyLarge.weight(.semibold))
                    .foregroundColor(AppColors.primary)
                
                Spacer()
            }
            .padding()
            .background(AppColors.cardBackground)
            .cornerRadius(AppShapes.cornerRadiusMedium)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Helper Properties
    
    private var userName: String {
        if let user = user {
            return user.username
        } else if let firebaseUser = Auth.auth().currentUser {
            return firebaseUser.displayName ?? "Vinyl Collector"
        }
        return "Vinyl Collector"
    }
    
    private var userEmail: String {
        if let user = user {
            return user.email
        } else if let firebaseUser = Auth.auth().currentUser {
            return firebaseUser.email ?? "No email"
        }
        return "No email"
    }
    
    private var userInitials: String {
        let name = userName
        let components = name.components(separatedBy: " ")
        
        if components.count > 1, let first = components.first?.first, let last = components.last?.first {
            return "\(first)\(last)"
        } else if let first = name.first {
            return String(first)
        }
        
        return "VC"
    }
    
    // MARK: - Actions
    
    private func loadUserProfile() {
        isLoading = true
        
        Task {
            do {
                let result = try await withCheckedThrowingContinuation { continuation in
                    socialService.fetchUserProfile { result in
                        continuation.resume(with: result)
                    }
                }
                
                user = result
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
                isLoading = false
            }
        }
    }
    
    private func uploadProfileImage(_ imageData: Data) {
        Task {
            do {
                let result = try await withCheckedThrowingContinuation { continuation in
                    socialService.uploadProfileImage(imageData) { result in
                        continuation.resume(with: result)
                    }
                }
                
                // Reload user profile to get updated image URL
                loadUserProfile()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func signOut() {
        do {
            try socialService.signOut()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

struct SimpleProfileView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleProfileView()
    }
}
