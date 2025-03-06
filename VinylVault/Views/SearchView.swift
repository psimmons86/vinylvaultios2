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
    @State private var viewMode: ViewMode = .grid
    
    let discogsService: DiscogsServiceWrapper
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // View Mode Selector
                    viewModeSelector
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // Search Results
                    if isSearching {
                        loadingView
                    } else if searchResults.isEmpty && !searchText.isEmpty {
                        emptyResultsView
                    } else {
                        // Collection Content
                        ScrollView {
                            switch viewMode {
                            case .grid:
                                gridView
                            case .list:
                                listView
                            case .compact:
                                compactView
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Search Discogs")
            .navigationBarTitleDisplayMode(.large)
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
                            .font(AppFonts.bodyLarge)
                            .foregroundColor(AppColors.textLight)
                            .padding()
                            .background(AppColors.accent1)
                            .cornerRadius(AppShapes.cornerRadiusMedium)
                            .shadow(color: AppColors.accent1.opacity(0.3), radius: 10, x: 0, y: 5)
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
    
    // MARK: - View Components
    
    private var viewModeSelector: some View {
        HStack {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.spring()) {
                        viewMode = mode
                    }
                } label: {
                    Text(mode.rawValue)
                        .font(AppFonts.bodyMedium.weight(viewMode == mode ? .bold : .regular))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            viewMode == mode ?
                            AppColors.secondary :
                            AppColors.background
                        )
                        .foregroundColor(
                            viewMode == mode ?
                            AppColors.textLight :
                            AppColors.textSecondary
                        )
                        .cornerRadius(AppShapes.cornerRadiusMedium)
                }
            }
            
            Spacer()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
                .tint(AppColors.secondary)
            
            Text("Searching Discogs...")
                .font(AppFonts.bodyLarge)
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyResultsView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textSecondary.opacity(0.5))
            
            Text("No results found")
                .font(AppFonts.titleMedium)
                .foregroundColor(AppColors.textSecondary)
            
            Text("Try a different search term")
                .font(AppFonts.bodyLarge)
                .foregroundColor(AppColors.textSecondary.opacity(0.7))
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var gridView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 180), spacing: 16)], spacing: 16) {
            ForEach(searchResults) { record in
                NavigationLink(destination: RecordDetailView(record: record)) {
                    RecordCardMedium(record: record)
                }
                .buttonStyle(PlainButtonStyle())
                .contextMenu {
                    addToCollectionButton(record: record)
                }
            }
        }
        .padding()
        .animation(.spring(), value: searchResults)
    }
    
    private var listView: some View {
        LazyVStack(spacing: 16) {
            ForEach(searchResults) { record in
                NavigationLink(destination: RecordDetailView(record: record)) {
                    RecordCardLarge(record: record)
                }
                .buttonStyle(PlainButtonStyle())
                .contextMenu {
                    addToCollectionButton(record: record)
                }
            }
        }
        .padding()
        .animation(.spring(), value: searchResults)
    }
    
    private var compactView: some View {
        LazyVStack(spacing: 12) {
            ForEach(searchResults) { record in
                NavigationLink(destination: RecordDetailView(record: record)) {
                    RecordCardRow(record: record)
                }
                .buttonStyle(PlainButtonStyle())
                .contextMenu {
                    addToCollectionButton(record: record)
                }
                .swipeActions {
                    Button {
                        addToCollection(record)
                    } label: {
                        if isAddingRecord {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Label("Add", systemImage: "plus")
                        }
                    }
                    .tint(AppColors.accent1)
                }
            }
        }
        .padding()
        .animation(.spring(), value: searchResults)
    }
    
    private func addToCollectionButton(record: Record) -> some View {
        Button {
            addToCollection(record)
        } label: {
            Label("Add to Collection", systemImage: "plus.circle")
        }
    }
    
    // MARK: - Actions
    
    private func addToCollection(_ record: Record) {
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
