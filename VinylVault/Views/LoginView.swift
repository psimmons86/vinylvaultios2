import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @EnvironmentObject var recordStore: RecordStore
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var isAuthenticated = false
    
    let discogsService: DiscogsServiceWrapper
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo and Title
                VStack(spacing: 10) {
                    Image(systemName: "record.circle")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Vinyl Vault")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(isSignUp ? "Create an account" : "Sign in to your account")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 20)
                
                // Form
                VStack(spacing: 15) {
                    if isSignUp {
                        TextField("Username", text: $username)
                            .textContentType(.username)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    SecureField("Password", text: $password)
                        .textContentType(isSignUp ? .newPassword : .password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Action Button
                Button(action: {
                    Task {
                        await authenticate()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    } else {
                        Text(isSignUp ? "Sign Up" : "Sign In")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .disabled(isLoading || !isFormValid)
                .padding(.horizontal)
                
                // Toggle between Sign In and Sign Up
                Button(action: {
                    isSignUp.toggle()
                    errorMessage = nil
                }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .foregroundColor(.blue)
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
            .alert(isPresented: $showingError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                // Check if user is already signed in
                isAuthenticated = Auth.auth().currentUser != nil
            }
        }
        .fullScreenCover(isPresented: $isAuthenticated) {
            MainTabView(discogsService: discogsService)
                .environmentObject(recordStore)
        }
    }
    
    private var isFormValid: Bool {
        if isSignUp {
            return !email.isEmpty && !password.isEmpty && !username.isEmpty && password.count >= 6
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    private func authenticate() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if isSignUp {
                _ = try await recordStore.signUp(email: email, password: password, username: username)
            } else {
                _ = try await recordStore.signIn(email: email, password: password)
            }
            
            // Fetch records after successful authentication
            await recordStore.fetchRecordsFromFirebase()
            
            isAuthenticated = true
        } catch {
            errorMessage = handleAuthError(error)
            showingError = true
        }
        
        isLoading = false
    }
    
    private func handleAuthError(_ error: Error) -> String {
        if let errorCode = AuthErrorCode.Code(rawValue: (error as NSError).code) {
            switch errorCode {
            case .invalidEmail:
                return "Invalid email address"
            case .wrongPassword:
                return "Incorrect password"
            case .userNotFound:
                return "No account found with this email"
            case .emailAlreadyInUse:
                return "This email is already in use"
            case .weakPassword:
                return "Password is too weak. Use at least 6 characters"
            case .networkError:
                return "Network error. Check your connection"
            default:
                return "Authentication error: \(error.localizedDescription)"
            }
        }
        return error.localizedDescription
    }
}

struct MainTabView: View {
    @EnvironmentObject var recordStore: RecordStore
    let discogsService: DiscogsServiceWrapper
    
    var body: some View {
        TabView {
            CollectionView()
                .tabItem {
                    Label("Collection", systemImage: "record.circle")
                }
            
            SearchView(discogsService: discogsService)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
        .environmentObject(recordStore)
        .environmentObject(discogsService)
    }
}

struct ProfileView: View {
    @EnvironmentObject var recordStore: RecordStore
    @State private var showingSignOutConfirmation = false
    @State private var navigateToLogin = false
    
    // Access the DiscogsService from the environment
    @EnvironmentObject var discogsService: DiscogsServiceWrapper
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account")) {
                    if let user = Auth.auth().currentUser {
                        HStack {
                            Text("Username")
                            Spacer()
                            Text(user.displayName ?? "Collector")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(user.email ?? "")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Collection Stats")) {
                    let stats = recordStore.collectionStats
                    
                    HStack {
                        Text("Total Records")
                        Spacer()
                        Text("\(stats.totalRecords)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Total Plays")
                        Spacer()
                        Text("\(stats.totalPlays)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Collection Value")
                        Spacer()
                        Text(stats.formattedTotalValue)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: {
                        showingSignOutConfirmation = true
                    }) {
                        HStack {
                            Text("Sign Out")
                                .foregroundColor(.red)
                            Spacer()
                            Image(systemName: "arrow.right.square")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
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
        .fullScreenCover(isPresented: $navigateToLogin) {
            LoginView(discogsService: discogsService)
                .environmentObject(recordStore)
        }
    }
    
    private func signOut() {
        do {
            try recordStore.signOut()
            navigateToLogin = true
        } catch {
            print("Error signing out: \(error)")
        }
    }
}

#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        let previewDiscogsService = DiscogsServiceWrapper(token: "preview_token")
        return LoginView(discogsService: previewDiscogsService)
            .environmentObject(RecordStore())
    }
}
#endif
