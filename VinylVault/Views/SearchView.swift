import SwiftUI

struct SearchView: View {
    @EnvironmentObject var recordStore: RecordStore
    @State private var searchText = ""
    @State private var searchResults: [Record] = []
    @State private var isSearching = false
    @State private var error: Error?
    @State private var showingError = false
    @State private var searchTask: Task<Void, Never>?
    @State private var showingSuccess = false
    @State private var successMessage = ""
    @State private var isAddingRecord = false
    @State private var hapticGenerator = UINotificationFeedbackGenerator()
    
    let discogsService: DiscogsServiceWrapper
    
    var body: some View {
        NavigationView {
            List {
                if isSearching {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    Text("No results found")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(searchResults) { record in
                        NavigationLink {
                            RecordDetailView(record: record)
                        } label: {
                            RecordRowView(record: record)
                        }
                        .swipeActions {
                            Button {
                                guard !isAddingRecord else { return }
                                isAddingRecord = true
                                
                                Task {
                                    // Simulate network delay
                                    try? await Task.sleep(for: .milliseconds(500))
                                    
                                    withAnimation {
                                        recordStore.addRecord(record)
                                        successMessage = "\(record.title) added to collection"
                                        showingSuccess = true
                                        isAddingRecord = false
                                        
                                        // Trigger success haptic
                                        hapticGenerator.notificationOccurred(.success)
                                        
                                        // Hide success message after 2 seconds
                                        Task {
                                            try? await Task.sleep(for: .seconds(2))
                                            withAnimation {
                                                showingSuccess = false
                                            }
                                        }
                                    }
                                }
                            } label: {
                                if isAddingRecord {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Label("Add", systemImage: "plus")
                                }
                            }
                            .tint(.green)
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Search for vinyl records")
            .keyboardShortcut("f", modifiers: .command) // Command+F to focus search
            .onChange(of: searchText) { newValue in
                searchTask?.cancel()
                
                guard !newValue.isEmpty else {
                    searchResults = []
                    return
                }
                
                searchTask = Task {
                    do {
                        try await Task.sleep(for: .milliseconds(500))
                        if !Task.isCancelled {
                            await search()
                        }
                    } catch {
                        if error is CancellationError {
                            // Search was cancelled, ignore the error
                            return
                        }
                        self.error = error
                        showingError = true
                    }
                }
            }
            .overlay {
                if showingSuccess {
                    VStack {
                        Spacer()
                        Text(successMessage)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green.opacity(0.8))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .padding(.horizontal)
                            .padding(.bottom, 30)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingSuccess)
            .alert(
                "Error",
                isPresented: $showingError,
                presenting: error as? DiscogsError
            ) { _ in
                Button("OK", role: .cancel) {}
            } message: { error in
                Text(error.localizedDescription)
            }
            .onAppear {
                #if DEBUG
                print("🔍 SearchView appeared")
                #endif
                
                // Prepare haptic feedback generator
                hapticGenerator.prepare()
            }
        }
    }
    
    @MainActor
    private func search() async {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        searchResults = []
        error = nil
        
        do {
            #if DEBUG
            print("🔍 Searching for: \(searchText)")
            #endif
            
            let results = try await discogsService.searchRecords(query: searchText)
            
            #if DEBUG
            print("✅ Found \(results.count) results")
            #endif
            
            // Only update results if we haven't started a new search
            if !Task.isCancelled {
                searchResults = results
                
                // Trigger success haptic if results found
                if !results.isEmpty {
                    hapticGenerator.notificationOccurred(.success)
                }
            }
        } catch {
            #if DEBUG
            print("❌ Search error: \(error.localizedDescription)")
            #endif
            
            self.error = error
            showingError = true
            hapticGenerator.notificationOccurred(.error)
        }
        
        isSearching = false
    }
}

#if DEBUG
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        let service = DiscogsServiceWrapper(token: "preview_token")
        let store = RecordStore()
        SearchView(discogsService: service)
            .environmentObject(store)
    }
}
#endif
