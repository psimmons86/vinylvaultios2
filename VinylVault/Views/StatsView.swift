import SwiftUI

struct StatsView: View {
    @EnvironmentObject var recordStore: RecordStore
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Summary Cards
                        summaryCardsSection
                        
                        // Format Distribution
                        statsSection(title: "Records by Format") {
                            formatsView
                        }
                        
                        // Top Artists
                        statsSection(title: "Top Artists") {
                            topArtistsView
                        }
                        
                        // Decades Distribution
                        statsSection(title: "Records by Decade") {
                            decadesView
                        }
                        
                        // Top Records Section
                        topRecordsSection
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Collection Stats")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - View Components
    
    private var summaryCardsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                statCard(
                    title: "Total Records",
                    value: "\(recordStore.records.count)",
                    icon: "music.note.list",
                    color: AppColors.primary
                )
                
                statCard(
                    title: "Total Plays",
                    value: "\(recordStore.records.reduce(0) { $0 + $1.plays })",
                    icon: "play.circle.fill",
                    color: AppColors.secondary
                )
                
                statCard(
                    title: "Collection Value",
                    value: "$\(String(format: "%.2f", recordStore.records.reduce(0) { $0 + $1.value }))",
                    icon: "dollarsign.circle.fill",
                    color: AppColors.tertiary
                )
                
                statCard(
                    title: "Most Common Format",
                    value: mostCommonFormat,
                    icon: "record.circle",
                    color: AppColors.accent1
                )
            }
            .padding(.horizontal)
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Text(title)
                    .font(AppFonts.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Text(value)
                .font(AppFonts.titleMedium)
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(width: 160, height: 100)
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(AppShapes.cornerRadiusMedium)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func statsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(AppFonts.titleSmall)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal)
            
            content()
                .padding()
                .background(AppColors.cardBackground)
                .cornerRadius(AppShapes.cornerRadiusMedium)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
        }
    }
    
    private var formatsView: some View {
        let formatCounts = formatDistribution
        let total = recordStore.records.count
        
        return VStack(spacing: 16) {
            // Pie chart visualization using basic SwiftUI
            HStack(alignment: .center, spacing: 0) {
                ForEach(formatCounts, id: \.format) { item in
                    let width = CGFloat(item.count) / CGFloat(total) * 300
                    Rectangle()
                        .fill(formatColor(for: item.format))
                        .frame(width: width, height: 20)
                        .overlay(
                            Text(item.count > 5 ? "\(item.count)" : "")
                                .font(AppFonts.bodySmall.weight(.bold))
                                .foregroundColor(.white)
                        )
                }
            }
            .cornerRadius(AppShapes.cornerRadiusSmall)
            
            // Legend
            HStack(spacing: 16) {
                ForEach(formatCounts, id: \.format) { item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(formatColor(for: item.format))
                            .frame(width: 12, height: 12)
                        
                        Text("\(item.format.rawValue) (\(item.count))")
                            .font(AppFonts.bodySmall)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                Spacer()
            }
        }
    }
    
    private var topArtistsView: some View {
        let artistCounts = topArtists.prefix(5)
        let maxCount = artistCounts.map { $0.count }.max() ?? 1
        
        return VStack(spacing: 12) {
            ForEach(Array(artistCounts.enumerated()), id: \.element.artist) { index, item in
                HStack {
                    Text(item.artist)
                        .font(AppFonts.bodyMedium)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                        .frame(width: 120, alignment: .leading)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.secondary, AppColors.accent2],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: CGFloat(item.count) / CGFloat(maxCount) * 150, height: 24)
                        .cornerRadius(AppShapes.cornerRadiusSmall)
                    
                    Text("\(item.count)")
                        .font(AppFonts.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 30, alignment: .trailing)
                }
            }
        }
    }
    
    private var decadesView: some View {
        let decadeCounts = decadeDistribution
        let maxCount = decadeCounts.map { $0.count }.max() ?? 1
        
        return VStack(spacing: 16) {
            ForEach(decadeCounts, id: \.decade) { item in
                HStack {
                    Text(item.decade)
                        .font(AppFonts.bodyMedium)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 60, alignment: .leading)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.tertiary, AppColors.accent1],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: CGFloat(item.count) / CGFloat(maxCount) * 150, height: 24)
                        .cornerRadius(AppShapes.cornerRadiusSmall)
                    
                    Text("\(item.count)")
                        .font(AppFonts.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 30, alignment: .trailing)
                }
            }
        }
    }
    
    private var topRecordsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Most Played Records")
                .font(AppFonts.titleSmall)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal)
            
            ForEach(topPlayedRecords) { record in
                HStack(spacing: 16) {
                    // Album Cover
                    AsyncImage(url: URL(string: record.imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: AppShapes.cornerRadiusSmall)
                                .fill(AppColors.secondary.opacity(0.1))
                                .overlay(
                                    Image(systemName: "music.note")
                                        .font(.system(size: 20))
                                        .foregroundColor(AppColors.secondary)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            RoundedRectangle(cornerRadius: AppShapes.cornerRadiusSmall)
                                .fill(AppColors.secondary.opacity(0.1))
                                .overlay(
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.system(size: 20))
                                        .foregroundColor(AppColors.secondary)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: AppShapes.cornerRadiusSmall))
                    
                    // Record Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.title)
                            .font(AppFonts.bodyLarge)
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(1)
                        
                        Text(record.artist)
                            .font(AppFonts.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Play Count
                    VStack(alignment: .trailing) {
                        Text("\(record.plays)")
                            .font(AppFonts.titleSmall)
                            .foregroundColor(AppColors.primary)
                        
                        Text("plays")
                            .font(AppFonts.bodySmall)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding()
                .background(AppColors.cardBackground)
                .cornerRadius(AppShapes.cornerRadiusMedium)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatColor(for format: RecordFormat) -> Color {
        switch format {
        case .lp:
            return AppColors.tertiary
        case .ep:
            return AppColors.accent1
        case .single:
            return AppColors.accent3
        }
    }
    
    // MARK: - Data Calculations
    
    private var formatDistribution: [(format: RecordFormat, count: Int)] {
        var counts: [RecordFormat: Int] = [:]
        
        for record in recordStore.records {
            counts[record.format, default: 0] += 1
        }
        
        return counts.map { (format: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    private var topArtists: [(artist: String, count: Int)] {
        var counts: [String: Int] = [:]
        
        for record in recordStore.records {
            counts[record.artist, default: 0] += 1
        }
        
        return counts.map { (artist: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    private var decadeDistribution: [(decade: String, count: Int)] {
        var counts: [String: Int] = [:]
        
        for record in recordStore.records {
            if let year = record.year {
                let decade = "\(year / 10 * 10)s"
                counts[decade, default: 0] += 1
            }
        }
        
        return counts.map { (decade: $0.key, count: $0.value) }
            .sorted { $0.decade < $1.decade }
    }
    
    private var topPlayedRecords: [Record] {
        return recordStore.records
            .filter { $0.plays > 0 }
            .sorted { $0.plays > $1.plays }
            .prefix(5)
            .map { $0 }
    }
    
    private var mostCommonFormat: String {
        let formatCounts = formatDistribution
        if let mostCommon = formatCounts.first {
            return mostCommon.format.rawValue
        }
        return "None"
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
            .environmentObject(RecordStore())
    }
}
