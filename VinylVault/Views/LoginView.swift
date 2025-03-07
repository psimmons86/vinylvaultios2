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
    
    let discogsService: DiscogsServiceWrapper
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    AppColors.primary, // Teal
                    AppColors.secondary // Magenta
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Logo and Title
                    VStack(spacing: 16) {
                        // Custom vinyl record logo
                        ZStack {
                            // Outer record
                            Circle()
                                .fill(Color.black)
                                .frame(width: 160, height: 160)
                                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                            
                            // Record grooves
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .frame(width: 140, height: 140)
                            
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .frame(width: 120, height: 120)
                            
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .frame(width: 100, height: 100)
                            
                            // Record label
                            Circle()
                                .fill(AppColors.secondary) // Magenta label
                                .frame(width: 60, height: 60)
                            
                            // Center hole
                            Circle()
                                .fill(Color.black)
                                .frame(width: 10, height: 10)
                            
                            // Reflection
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0)
                                        ]),
                                        center: .topLeading,
                                        startRadius: 0,
                                        endRadius: 80
                                    )
                                )
                                .frame(width: 160, height: 160)
                        }
                        
                        Text("VINYL VAULT")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(isSignUp ? "Create an account" : "Sign in to your account")
                            .font(AppFonts.bodyLarge)
                            .foregroundColor(.white)
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 20)
                    
                    // Form
                    VStack(spacing: 16) {
                        if isSignUp {
                            textField(
                                title: "Username",
                                text: $username,
                                icon: "person.fill",
                                contentType: .username
                            )
                        }
                        
                        textField(
                            title: "Email",
                            text: $email,
                            icon: "envelope.fill",
                            contentType: .emailAddress,
                            keyboardType: .emailAddress
                        )
                        
                        secureField(
                            title: "Password",
                            text: $password,
                            icon: "lock.fill",
                            contentType: isSignUp ? .newPassword : .password
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // Action Button
                    VStack(spacing: 16) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.textLight))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(AppColors.primary)
                                .cornerRadius(AppShapes.cornerRadiusMedium)
                                .padding(.horizontal, 24)
                        } else {
                            Button {
                                Task {
                                    await authenticate()
                                }
                            } label: {
                                Text(isSignUp ? "Create Account" : "Sign In")
                                    .font(AppFonts.bodyLarge.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(isFormValid ? AppColors.primary : AppColors.primary.opacity(0.3))
                                    .foregroundColor(AppColors.textLight)
                                    .cornerRadius(AppShapes.cornerRadiusMedium)
                                    .padding(.horizontal, 24)
                            }
                            .disabled(!isFormValid)
                        }
                        
                        // Toggle between Sign In and Sign Up
                        Button {
                            withAnimation {
                                isSignUp.toggle()
                                errorMessage = nil
                            }
                        } label: {
                            Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                .font(AppFonts.bodyMedium)
                                .foregroundColor(AppColors.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 30)
            }
        }
        .alert(isPresented: $showingError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            // Check if user is already signed in
            if Auth.auth().currentUser != nil {
                isLoggedIn = true
            }
        }
    }
    
    // MARK: - Custom Components
    
    private func textField(
        title: String,
        text: Binding<String>,
        icon: String,
        contentType: UITextContentType? = nil,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFonts.bodyMedium)
                .foregroundColor(.white)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 24)
                
                TextField("", text: text)
                    .font(AppFonts.bodyLarge)
                    .foregroundColor(AppColors.textPrimary)
                    .textContentType(contentType)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            .padding()
            .background(Color.white.opacity(0.9))
            .cornerRadius(AppShapes.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: AppShapes.cornerRadiusMedium)
                    .stroke(AppColors.primary, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
        }
    }
    
    private func secureField(
        title: String,
        text: Binding<String>,
        icon: String,
        contentType: UITextContentType? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFonts.bodyMedium)
                .foregroundColor(.white)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 24)
                
                SecureField("", text: text)
                    .font(AppFonts.bodyLarge)
                    .foregroundColor(AppColors.textPrimary)
                    .textContentType(contentType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            .padding()
            .background(Color.white.opacity(0.9))
            .cornerRadius(AppShapes.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: AppShapes.cornerRadiusMedium)
                    .stroke(AppColors.primary, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
        }
    }
    
    // MARK: - Validation & Authentication
    
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
            
            isLoggedIn = true
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

// MARK: - Preview
#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        let previewDiscogsService = DiscogsServiceWrapper(token: "preview_token")
        return LoginView(discogsService: previewDiscogsService, isLoggedIn: .constant(false))
            .environmentObject(RecordStore())
    }
}
#endif
