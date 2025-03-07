import SwiftUI
import Charts

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
                        
                        // Format Distribution Chart
                        chartSection(title: "Records by Format") {
                            formatsChart
                        }
                        
                        // Top Artists Chart
                        chartSection(title: "Top Artists") {
                            artistsChart
                        }
                        
                        // Decades Chart
                        chartSection(title: "Records by Decade") {
                            decadesChart
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
    
    private func chartSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(AppFonts.titleSmall)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal)
            
            content()
                .frame(height: 300)
                .padding()
                .background(AppColors.cardBackground)
                .cornerRadius(AppShapes.cornerRadiusMedium)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
        }
    }
    
    private var formatsChart: some View {
        let formatCounts = formatDistribution
        
        return Chart {
            ForEach(formatCounts, id: \.format) { item in
                SectorMark(
                    angle: .value("Count", item.count),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.5
                )
                .cornerRadius(5)
                .foregroundStyle(formatColor(for: item.format))
                .annotation(position: .overlay) {
                    Text("\(item.count)")
                        .font(AppFonts.bodySmall.weight(.bold))
                        .foregroundColor(.white)
                }
            }
        }
        .chartBackground { chartProxy in
            GeometryReader { geometry in
                let frame = geometry[chartProxy.plotAreaFrame]
                VStack {
                    Text("Total")
                        .font(AppFonts.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                    Text("\(recordStore.records.count)")
                        .font(AppFonts.titleMedium)
                        .foregroundColor(AppColors.textPrimary)
                }
                .position(x: frame.midX, y: frame.midY)
            }
        }
    }
    
    private var artistsChart: some View {
        let artistCounts = topArtists.prefix(5)
        
        return Chart(artistCounts, id: \.artist) { item in
            BarMark(
                x: .value("Count", item.count),
                y: .value("Artist", item.artist)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [AppColors.secondary, AppColors.accent2],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(6)
        }
        .chartYAxis {
            AxisMarks(preset: .aligned) { value in
                AxisValueLabel {
                    if let artist = value.as(String.self) {
                        Text(artist)
                            .font(AppFonts.bodySmall)
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let count = value.as(Int.self) {
                        Text("\(count)")
                            .font(AppFonts.bodySmall)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
    }
    
    private var decadesChart: some View {
        let decadeCounts = decadeDistribution
        
        return Chart {
            ForEach(decadeCounts, id: \.decade) { item in
                BarMark(
                    x: .value("Decade", item.decade),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.tertiary, AppColors.accent1],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(6)
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let decade = value.as(String.self) {
                        Text(decade)
                            .font(AppFonts.bodySmall)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let count = value.as(Int.self) {
                        Text("\(count)")
                            .font(AppFonts.bodySmall)
                            .foregroundColor(AppColors.textSecondary)
                    }
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
