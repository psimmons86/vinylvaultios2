import Foundation

enum RecordFormat: String, Codable, CaseIterable {
    case lp = "LP"
    case ep = "EP"
    case single = "Single"
}

struct Record: Identifiable, Codable {
    let id: UUID
    var title: String
    var artist: String
    var year: Int?
    var format: RecordFormat
    var tags: [String] = []
    var plays: Int
    var lastPlayed: Date?
    var imageUrl: String
    var notes: String?
    var value: Double
    var discogsId: String? // Can be either String or Int from Discogs API
    var label: String?
    var inHeavyRotation: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        year: Any? = nil,
        format: RecordFormat = .lp,
        tags: [String] = [],
        plays: Int = 0,
        lastPlayed: Date? = nil,
        imageUrl: String = "default-album",
        notes: String? = nil,
        value: Double = 0.0,
        discogsId: String? = nil,
        label: String? = nil,
        inHeavyRotation: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        // Handle year which can be Int, String, or nil
        if let yearInt = year as? Int {
            self.year = yearInt
        } else if let yearString = year as? String, let yearInt = Int(yearString) {
            self.year = yearInt
        } else {
            self.year = nil
        }
        self.format = format
        self.tags = tags
        self.plays = plays
        self.lastPlayed = lastPlayed
        self.imageUrl = imageUrl
        self.notes = notes
        self.value = value
        self.discogsId = discogsId
        self.label = label
        self.inHeavyRotation = inHeavyRotation
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Computed properties for formatted dates
    var formattedLastPlayed: String {
        guard let lastPlayed = lastPlayed else { return "Never played" }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: lastPlayed)
    }
    
    var timeSinceLastPlayed: String {
        guard let lastPlayed = lastPlayed else { return "Never played" }
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: lastPlayed, to: now)
        guard let days = components.day else { return "Unknown" }
        
        if days == 0 { return "Today" }
        if days == 1 { return "Yesterday" }
        return "\(days) days ago"
    }
    
    // Mutating methods
    mutating func incrementPlays() {
        plays += 1
        lastPlayed = Date()
        updatedAt = Date()
    }
    
    mutating func addTag(_ tag: String) {
        let normalizedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !tags.contains(normalizedTag) && normalizedTag.count <= 50 {
            tags.append(normalizedTag)
            updatedAt = Date()
        }
    }
    
    mutating func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag.lowercased() }
        updatedAt = Date()
    }
}

// Extension for sorting and filtering
extension Array where Element == Record {
    func sortedByCreatedAt() -> [Record] {
        self.sorted { $0.createdAt > $1.createdAt }
    }
    
    func sortedByArtist() -> [Record] {
        self.sorted { $0.artist.lowercased() < $1.artist.lowercased() }
    }
    
    func sortedByPlays() -> [Record] {
        self.sorted { $0.plays > $1.plays }
    }
    
    func filterByTag(_ tag: String) -> [Record] {
        self.filter { $0.tags.contains(tag.lowercased()) }
    }
    
    func filterByYear(_ year: Int) -> [Record] {
        self.filter { $0.year == year }
    }
    
    func filterHeavyRotation() -> [Record] {
        self.filter { $0.inHeavyRotation }
    }
}
