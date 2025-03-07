import SwiftUI
import FirebaseAuth
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var recordStore: RecordStore
    @State private var showingSignOutConfirmation = false
    @State private var isLoggedIn = true
    @State private var profileImage: UIImage?
    @State private var showingImagePicker = false
    @State private var photoPickerItem: PhotosPickerItem?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // User Info Section
                        userInfoSection
                        
                        // Collection Stats Section
                        collectionStatsSection
                        
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
                }
            }
        }
    }
    
    private var collectionStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Collection Stats")
                .font(AppFonts.titleSmall)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                statRow(
                    title: "Total Records",
                    value: "\(recordStore.records.count)",
                    icon: "music.note.list",
                    color: AppColors.primary
                )
                
                Divider()
                
                statRow(
                    title: "Total Plays",
                    value: "\(recordStore.records.reduce(0) { $0 + $1.plays })",
                    icon: "play.circle.fill",
                    color: AppColors.secondary
                )
                
                Divider()
                
                statRow(
                    title: "Collection Value",
                    value: "$\(String(format: "%.2f", recordStore.records.reduce(0) { $0 + $1.value }))",
                    icon: "dollarsign.circle.fill",
                    color: AppColors.tertiary
                )
                
                Divider()
                
                statRow(
                    title: "Most Common Format",
                    value: mostCommonFormat,
                    icon: "record.circle",
                    color: AppColors.accent1
                )
            }
            .padding()
            .background(AppColors.cardBackground)
            .cornerRadius(AppShapes.cornerRadiusMedium)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            .padding(.horizontal)
        }
    }
    
    private func statRow(title: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .font(AppFonts.bodyLarge)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(AppFonts.bodyLarge.weight(.semibold))
                .foregroundColor(AppColors.textPrimary)
        }
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(AppFonts.titleSmall)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                NavigationLink(destination: UsersView()) {
                    settingsRowContent(title: "Manage Users", icon: "person.2.fill", color: AppColors.primary)
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
        if let user = Auth.auth().currentUser {
            return user.displayName ?? "Vinyl Collector"
        }
        return "Vinyl Collector"
    }
    
    private var userEmail: String {
        if let user = Auth.auth().currentUser {
            return user.email ?? "No email"
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
    
    private var mostCommonFormat: String {
        var counts: [RecordFormat: Int] = [:]
        
        for record in recordStore.records {
            counts[record.format, default: 0] += 1
        }
        
        let sorted = counts.sorted { $0.value > $1.value }
        if let first = sorted.first {
            return first.key.rawValue
        }
        
        return "None"
    }
    
    // MARK: - Actions
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(RecordStore())
    }
}
