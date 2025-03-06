import SwiftUI

enum ViewMode: String, CaseIterable {
    case grid = "Grid"
    case list = "List"
    case compact = "Compact"
}

struct CollectionView: View {
    @EnvironmentObject var recordStore: RecordStore
    @State private var viewMode: ViewMode = .grid
    @State private var searchText = ""
    @State private var showingAddRecord = false
    @State private var showingFilters = false
    @State private var selectedArtistFilter: String?
    @State private var selectedYearFilter: Int?
    @State private var selectedFormatFilter: RecordFormat?
    
    private var filteredRecords: [Record] {
        var records = recordStore.records
        
        // Apply search filter
        if !searchText.isEmpty {
            records = records.filter { record in
                record.title.localizedCaseInsensitiveContains(searchText) ||
                record.artist.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply artist filter
        if let artist = selectedArtistFilter {
            records = records.filter { $0.artist == artist }
        }
        
        // Apply year filter
        if let year = selectedYearFilter {
            records = records.filter { $0.year == year }
        }
        
        // Apply format filter
        if let format = selectedFormatFilter {
            records = records.filter { $0.format == format }
        }
        
        return records
    }
    
    private var artists: [String] {
        Array(Set(recordStore.records.map { $0.artist })).sorted()
    }
    
    private var years: [Int] {
        Array(Set(recordStore.records.compactMap { $0.year })).sorted()
    }
    
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
                    
                    // Filter Chips
                    filterChips
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
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
            .navigationTitle("My Collection")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFilters = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(AppColors.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddRecord = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search your collection")
            .sheet(isPresented: $showingAddRecord) {
                Text("Add Record View")
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingFilters) {
                filterSheet
                    .presentationDetents([.medium])
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
                            AppColors.primary :
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
    
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if selectedArtistFilter != nil || selectedYearFilter != nil || selectedFormatFilter != nil {
                    Button {
                        withAnimation {
                            selectedArtistFilter = nil
                            selectedYearFilter = nil
                            selectedFormatFilter = nil
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Clear All")
                                .font(AppFonts.bodySmall)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 10))
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(AppColors.accent2.opacity(0.1))
                        .foregroundColor(AppColors.accent2)
                        .cornerRadius(AppShapes.cornerRadiusSmall)
                    }
                }
                
                if let artist = selectedArtistFilter {
                    filterChip(text: artist, color: AppColors.accent1) {
                        withAnimation {
                            selectedArtistFilter = nil
                        }
                    }
                }
                
                if let year = selectedYearFilter {
                    filterChip(text: "\(year)", color: AppColors.accent3) {
                        withAnimation {
                            selectedYearFilter = nil
                        }
                    }
                }
                
                if let format = selectedFormatFilter {
                    filterChip(text: format.rawValue, color: AppColors.tertiary) {
                        withAnimation {
                            selectedFormatFilter = nil
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
    
    private func filterChip(text: String, color: Color, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(text)
                .font(AppFonts.bodySmall)
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(AppShapes.cornerRadiusSmall)
    }
    
    private var gridView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 180), spacing: 16)], spacing: 16) {
            ForEach(filteredRecords) { record in
                NavigationLink(destination: RecordDetailView(record: record)) {
                    RecordCardMedium(record: record)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .animation(.spring(), value: filteredRecords)
    }
    
    private var listView: some View {
        LazyVStack(spacing: 16) {
            ForEach(filteredRecords) { record in
                NavigationLink(destination: RecordDetailView(record: record)) {
                    RecordCardLarge(record: record)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .animation(.spring(), value: filteredRecords)
    }
    
    private var compactView: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredRecords) { record in
                NavigationLink(destination: RecordDetailView(record: record)) {
                    RecordCardRow(record: record)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .animation(.spring(), value: filteredRecords)
    }
    
    private var filterSheet: some View {
        NavigationView {
            List {
                Section("Artist") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(artists, id: \.self) { artist in
                                Button {
                                    selectedArtistFilter = artist
                                    showingFilters = false
                                } label: {
                                    Text(artist)
                                        .font(AppFonts.bodyMedium)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(
                                            selectedArtistFilter == artist ?
                                            AppColors.accent1 :
                                            AppColors.accent1.opacity(0.1)
                                        )
                                        .foregroundColor(
                                            selectedArtistFilter == artist ?
                                            AppColors.textLight :
                                            AppColors.accent1
                                        )
                                        .cornerRadius(AppShapes.cornerRadiusSmall)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Year") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(years, id: \.self) { year in
                                Button {
                                    selectedYearFilter = year
                                    showingFilters = false
                                } label: {
                                    Text("\(year)")
                                        .font(AppFonts.bodyMedium)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(
                                            selectedYearFilter == year ?
                                            AppColors.accent3 :
                                            AppColors.accent3.opacity(0.1)
                                        )
                                        .foregroundColor(
                                            selectedYearFilter == year ?
                                            AppColors.textLight :
                                            AppColors.accent3
                                        )
                                        .cornerRadius(AppShapes.cornerRadiusSmall)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Format") {
                    HStack(spacing: 8) {
                        ForEach(RecordFormat.allCases, id: \.self) { format in
                            Button {
                                selectedFormatFilter = format
                                showingFilters = false
                            } label: {
                                Text(format.rawValue)
                                    .font(AppFonts.bodyMedium)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(
                                        selectedFormatFilter == format ?
                                        AppColors.tertiary :
                                        AppColors.tertiary.opacity(0.1)
                                    )
                                    .foregroundColor(
                                        selectedFormatFilter == format ?
                                        AppColors.textLight :
                                        AppColors.tertiary
                                    )
                                    .cornerRadius(AppShapes.cornerRadiusSmall)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Filter Records")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingFilters = false
                    }
                }
            }
        }
    }
}

// MARK: - Preview
struct CollectionView_Previews: PreviewProvider {
    static var previews: some View {
        CollectionView()
            .environmentObject(RecordStore())
    }
}
