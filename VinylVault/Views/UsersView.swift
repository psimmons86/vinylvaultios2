import SwiftUI
import Firebase

// Import User model
@_exported import struct VinylVault.User
@_exported import enum VinylVault.UserRole
@_exported import struct VinylVault.CollaborationInvite

struct UsersView: View {
    @EnvironmentObject var recordStore: RecordStore
    @State private var showingInviteSheet = false
    @State private var inviteEmail = ""
    @State private var selectedRole = UserRole.viewer
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var activeTab = 0 // 0 = Collaborators, 1 = Invites
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab selector
                    HStack(spacing: 0) {
                        tabButton(title: "Collaborators", index: 0)
                        tabButton(title: "Invites", index: 1)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Content
                    TabView(selection: $activeTab) {
                        collaboratorsTab
                            .tag(0)
                        
                        invitesTab
                            .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Users")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingInviteSheet = true
                    }) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .disabled(!canInviteUsers())
                }
            }
            .sheet(isPresented: $showingInviteSheet) {
                inviteUserSheet
            }
            .alert("Error", isPresented: $showingError, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text(errorMessage ?? "An unknown error occurred")
            })
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
        }
    }
    
    // MARK: - Tabs
    
    private var collaboratorsTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                if recordStore.collaborators.isEmpty {
                    emptyCollaboratorsView
                } else {
                    ForEach(recordStore.collaborators) { user in
                        collaboratorCard(user: user)
                    }
                }
            }
            .padding()
        }
    }
    
    private var invitesTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                if recordStore.sentInvites.isEmpty && recordStore.pendingInvites.isEmpty {
                    emptyInvitesView
                } else {
                    // Pending invites (invites sent to the current user)
                    if !recordStore.pendingInvites.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Invitations for You")
                                .font(AppFonts.titleSmall)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal)
                            
                            ForEach(recordStore.pendingInvites) { invite in
                                pendingInviteCard(invite: invite)
                            }
                        }
                    }
                    
                    // Sent invites (invites sent by the current user)
                    if !recordStore.sentInvites.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Invitations You've Sent")
                                .font(AppFonts.titleSmall)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal)
                                .padding(.top, recordStore.pendingInvites.isEmpty ? 0 : 16)
                            
                            ForEach(recordStore.sentInvites) { invite in
                                sentInviteCard(invite: invite)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty States
    
    private var emptyCollaboratorsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textSecondary.opacity(0.5))
                .padding(.bottom, 8)
            
            Text("No Collaborators Yet")
                .font(AppFonts.titleMedium)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Invite others to collaborate on your vinyl collection")
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            
            if canInviteUsers() {
                Button(action: {
                    showingInviteSheet = true
                }) {
                    Text("Invite Users")
                        .font(AppFonts.bodyLarge.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppColors.primary)
                        .cornerRadius(AppShapes.cornerRadiusMedium)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppColors.cardBackground)
        .cornerRadius(AppShapes.cornerRadiusMedium)
    }
    
    private var emptyInvitesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textSecondary.opacity(0.5))
                .padding(.bottom, 8)
            
            Text("No Invitations")
                .font(AppFonts.titleMedium)
                .foregroundColor(AppColors.textPrimary)
            
            Text("You don't have any pending invitations")
                .font(AppFonts.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            
            if canInviteUsers() {
                Button(action: {
                    showingInviteSheet = true
                }) {
                    Text("Invite Users")
                        .font(AppFonts.bodyLarge.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppColors.primary)
                        .cornerRadius(AppShapes.cornerRadiusMedium)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppColors.cardBackground)
        .cornerRadius(AppShapes.cornerRadiusMedium)
    }
    
    // MARK: - Cards
    
    private func collaboratorCard(user: User) -> some View {
        VStack(spacing: 0) {
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
                
                // Role badge
                Text(user.role.rawValue)
                    .font(AppFonts.bodySmall.weight(.medium))
                    .foregroundColor(roleColor(for: user.role))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(roleColor(for: user.role).opacity(0.1))
                    .cornerRadius(AppShapes.cornerRadiusSmall)
            }
            .padding()
            
            // Actions
            if canManageUsers() && currentUserId != user.id {
                Divider()
                    .padding(.horizontal)
                
                HStack {
                    // Change role button
                    Menu {
                        ForEach(UserRole.allCases, id: \.self) { role in
                            Button(action: {
                                updateUserRole(user: user, newRole: role)
                            }) {
                                HStack {
                                    Text(role.rawValue)
                                    if user.role == role {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Text("Change Role")
                            .font(AppFonts.bodyMedium)
                            .foregroundColor(AppColors.primary)
                    }
                    
                    Spacer()
                    
                    // Remove button
                    Button(action: {
                        removeUser(user: user)
                    }) {
                        Text("Remove")
                            .font(AppFonts.bodyMedium)
                            .foregroundColor(AppColors.error)
                    }
                }
                .padding()
            }
        }
        .background(AppColors.cardBackground)
        .cornerRadius(AppShapes.cornerRadiusMedium)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func pendingInviteCard(invite: CollaborationInvite) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(invite.inviterName) invited you")
                        .font(AppFonts.bodyLarge.weight(.semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Role: \(invite.role.rawValue)")
                        .font(AppFonts.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                // Expiration
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Expires")
                        .font(AppFonts.captionMedium)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text(formatDate(invite.expiresAt))
                        .font(AppFonts.captionMedium)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            HStack(spacing: 16) {
                // Decline button
                Button(action: {
                    declineInvite(invite: invite)
                }) {
                    Text("Decline")
                        .font(AppFonts.bodyMedium.weight(.medium))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppColors.cardBackground)
                        .cornerRadius(AppShapes.cornerRadiusMedium)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppShapes.cornerRadiusMedium)
                                .stroke(AppColors.textSecondary.opacity(0.3), lineWidth: 1)
                        )
                }
                
                // Accept button
                Button(action: {
                    acceptInvite(invite: invite)
                }) {
                    Text("Accept")
                        .font(AppFonts.bodyMedium.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppColors.primary)
                        .cornerRadius(AppShapes.cornerRadiusMedium)
                }
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(AppShapes.cornerRadiusMedium)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func sentInviteCard(invite: CollaborationInvite) -> some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(invite.inviteeEmail)
                        .font(AppFonts.bodyLarge.weight(.semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: 8) {
                        // Role
                        Text(invite.role.rawValue)
                            .font(AppFonts.captionMedium.weight(.medium))
                            .foregroundColor(roleColor(for: invite.role))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(roleColor(for: invite.role).opacity(0.1))
                            .cornerRadius(AppShapes.cornerRadiusSmall)
                        
                        // Status
                        Text(invite.status.rawValue)
                            .font(AppFonts.captionMedium.weight(.medium))
                            .foregroundColor(statusColor(for: invite.status))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(statusColor(for: invite.status).opacity(0.1))
                            .cornerRadius(AppShapes.cornerRadiusSmall)
                    }
                }
                
                Spacer()
                
                if invite.status == .pending {
                    // Cancel button
                    Button(action: {
                        cancelInvite(invite: invite)
                    }) {
                        Text("Cancel")
                            .font(AppFonts.bodyMedium)
                            .foregroundColor(AppColors.error)
                    }
                }
            }
            
            // Date info
            HStack {
                Text("Sent: \(formatDate(invite.createdAt))")
                    .font(AppFonts.captionMedium)
                    .foregroundColor(AppColors.textSecondary)
                
                Spacer()
                
                Text("Expires: \(formatDate(invite.expiresAt))")
                    .font(AppFonts.captionMedium)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(AppShapes.cornerRadiusMedium)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Invite Sheet
    
    private var inviteUserSheet: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email Address")
                            .font(AppFonts.bodyMedium)
                            .foregroundColor(AppColors.textPrimary)
                        
                        TextField("Enter email address", text: $inviteEmail)
                            .font(AppFonts.bodyLarge)
                            .padding()
                            .background(AppColors.cardBackground)
                            .cornerRadius(AppShapes.cornerRadiusMedium)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    // Role selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Role")
                            .font(AppFonts.bodyMedium)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Picker("Select Role", selection: $selectedRole) {
                            ForEach(UserRole.allCases, id: \.self) { role in
                                Text(role.rawValue)
                                    .tag(role)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Role description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Permissions")
                            .font(AppFonts.bodyMedium)
                            .foregroundColor(AppColors.textPrimary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            rolePermissionRow(
                                title: "View Records",
                                description: "Can view all records in the collection",
                                isAllowed: true
                            )
                            
                            rolePermissionRow(
                                title: "Edit Records",
                                description: "Can add, edit, and delete records",
                                isAllowed: selectedRole == .owner || selectedRole == .editor
                            )
                            
                            rolePermissionRow(
                                title: "Manage Users",
                                description: "Can invite and manage other users",
                                isAllowed: selectedRole == .owner
                            )
                        }
                        .padding()
                        .background(AppColors.cardBackground)
                        .cornerRadius(AppShapes.cornerRadiusMedium)
                    }
                    
                    Spacer()
                    
                    // Invite button
                    Button(action: {
                        inviteUser()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Send Invitation")
                                .font(AppFonts.bodyLarge.weight(.semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValidEmail(inviteEmail) ? AppColors.primary : AppColors.textSecondary.opacity(0.3))
                    .cornerRadius(AppShapes.cornerRadiusMedium)
                    .disabled(!isValidEmail(inviteEmail) || isLoading)
                }
                .padding()
            }
            .navigationTitle("Invite User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingInviteSheet = false
                    }
                }
            }
        }
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
    
    private func rolePermissionRow(title: String, description: String, isAllowed: Bool) -> some View {
        HStack(spacing: 16) {
            Image(systemName: isAllowed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(isAllowed ? AppColors.success : AppColors.textSecondary.opacity(0.5))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.bodyMedium.weight(.medium))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(description)
                    .font(AppFonts.captionMedium)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Actions
    
    private func loadData() async {
        await recordStore.fetchCollaborators()
        await recordStore.fetchPendingInvites()
        await recordStore.fetchSentInvites()
    }
    
    private func inviteUser() {
        guard isValidEmail(inviteEmail) else { return }
        
        isLoading = true
        
        Task {
            do {
                try await recordStore.inviteUser(email: inviteEmail, role: selectedRole)
                isLoading = false
                showingInviteSheet = false
                inviteEmail = ""
                selectedRole = .viewer
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func acceptInvite(invite: CollaborationInvite) {
        Task {
            do {
                try await recordStore.acceptInvite(inviteId: invite.id)
                await loadData()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func declineInvite(invite: CollaborationInvite) {
        Task {
            do {
                try await recordStore.declineInvite(inviteId: invite.id)
                await loadData()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func cancelInvite(invite: CollaborationInvite) {
        Task {
            do {
                try await recordStore.cancelInvite(inviteId: invite.id)
                await loadData()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func updateUserRole(user: User, newRole: UserRole) {
        Task {
            do {
                try await recordStore.updateCollaboratorRole(userId: user.id, newRole: newRole)
                await loadData()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func removeUser(user: User) {
        Task {
            do {
                try await recordStore.removeCollaborator(userId: user.id)
                await loadData()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func userInitials(for user: User) -> String {
        let name = user.username
        let components = name.components(separatedBy: " ")
        
        if components.count > 1, let first = components.first?.first, let last = components.last?.first {
            return "\(first)\(last)"
        } else if let first = name.first {
            return String(first)
        }
        
        return "U"
    }
    
    private func roleColor(for role: UserRole) -> Color {
        switch role {
        case .owner:
            return AppColors.primary
        case .editor:
            return AppColors.secondary
        case .viewer:
            return AppColors.textSecondary
        }
    }
    
    private func statusColor(for status: CollaborationInvite.InviteStatus) -> Color {
        switch status {
        case .pending:
            return AppColors.warning
        case .accepted:
            return AppColors.success
        case .declined, .expired:
            return AppColors.error
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email) && email.count > 5
    }
    
    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    private func canManageUsers() -> Bool {
        // Find the current user in collaborators
        if let currentUser = Auth.auth().currentUser {
            // If the user is not in collaborators, they might be the owner
            return true
        }
        return false
    }
    
    private func canInviteUsers() -> Bool {
        return canManageUsers()
    }
}

struct UsersView_Previews: PreviewProvider {
    static var previews: some View {
        UsersView()
            .environmentObject(RecordStore())
    }
}
