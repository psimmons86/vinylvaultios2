import SwiftUI

struct CollectionView: View {
    @EnvironmentObject var recordStore: RecordStore
    @State private var sortOption = SortOption.artist
    @State private var filterTag: String?
    @State private var showingStats = false
    @State private var searchText = ""
    
    enum SortOption: String, CaseIterable {
        case artist = "Artist"
        case recent = "Recently Added"
        case plays = "Most Played"
        case year = "Year"
    }
    
    var filteredRecords: [Record] {
        var records = recordStore.records
        
        // Apply search filter
        if !searchText.isEmpty {
            records = records.filter { record in
                record.title.localizedCaseInsensitiveContains(searchText) ||
                record.artist.localizedCaseInsensitiveContains(searchText) ||
                record.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Apply tag filter
        if let tag = filterTag {
            records = records.filter { $0.tags.contains(tag.lowercased()) }
        }
        
        // Apply sort
        switch sortOption {
        case .artist:
            return records.sortedByArtist()
        case .recent:
            return records.sortedByCreatedAt()
        case .plays:
            return records.sortedByPlays()
        case .year:
            return records.sorted { ($0.year ?? 0) > ($1.year ?? 0) }
        }
    }
    
    var allTags: [String] {
        Array(Set(recordStore.records.flatMap(\.tags))).sorted()
    }
    
    var body: some View {
        NavigationView {
            List {
                if recordStore.records.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No Records")
                            .font(.title2)
                            .foregroundColor(.primary)
                        Text("Add records by searching the Discogs database")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredRecords) { record in
                        NavigationLink {
                            RecordDetailView(record: record)
                        } label: {
                            RecordRowView(record: record)
                        }
                    }
                }
            }
            .navigationTitle("Collection")
            .searchable(text: $searchText, prompt: "Search your collection")
            .navigationBarItems(trailing:
                Menu {
                    Picker("Sort by", selection: $sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue)
                        }
                    }
                    
                    Divider()
                    
                    Menu("Filter by Tag") {
                        Button("All Records") {
                            filterTag = nil
                        }
                        
                        Divider()
                        
                        ForEach(allTags, id: \.self) { tag in
                            Button {
                                filterTag = tag
                            } label: {
                                if filterTag == tag {
                                    Label(tag, systemImage: "checkmark")
                                } else {
                                    Text(tag)
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    Button {
                        showingStats = true
                    } label: {
                        Label("Collection Stats", systemImage: "chart.bar")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            )
            .sheet(isPresented: $showingStats) {
                StatsView(stats: recordStore.collectionStats)
            }
        }
    }
}

struct StatsView: View {
    let stats: CollectionStats
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Overview") {
                    StatRow(title: "Total Records", value: "\(stats.totalRecords)")
                    StatRow(title: "Total Plays", value: "\(stats.totalPlays)")
                    StatRow(title: "Average Plays", value: String(format: "%.1f", stats.averagePlays))
                    StatRow(title: "Collection Value", value: stats.formattedTotalValue)
                }
                
                Section("Top Artists") {
                    ForEach(stats.topArtists, id: \.artist) { artist, count in
                        HStack {
                            Text(artist)
                            Spacer()
                            Text("\(count)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Records by Decade") {
                    ForEach(stats.yearDistribution.sorted(by: { $0.key > $1.key }), id: \.key) { decade, count in
                        HStack {
                            Text("\(decade)s")
                            Spacer()
                            Text("\(count)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Collection Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct CollectionView_Previews: PreviewProvider {
    static var previews: some View {
        CollectionView()
            .environmentObject(RecordStore())
    }
}
