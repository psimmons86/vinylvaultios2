import Foundation
import Firebase

@MainActor
class RecordStore: ObservableObject {
    @Published private(set) var records: [Record] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let firebaseService = FirebaseService.shared
    private let defaults = UserDefaults.standard
    private let recordsKey = "savedRecords"
    
    init() {
        // First load from local storage for immediate display
        loadLocalRecords()
        
        // Then fetch from Firebase if user is logged in
        if Auth.auth().currentUser != nil {
            Task {
                await fetchRecordsFromFirebase()
            }
        }
    }
    
    private func loadLocalRecords() {
        guard let data = defaults.data(forKey: recordsKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            records = try decoder.decode([Record].self, from: data)
        } catch {
            print("Error loading records from local storage: \(error)")
        }
    }
    
    private func saveLocalRecords() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(records)
            defaults.set(data, forKey: recordsKey)
        } catch {
            print("Error saving records to local storage: \(error)")
        }
    }
    
    func fetchRecordsFromFirebase() async {
        guard Auth.auth().currentUser != nil else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await withCheckedThrowingContinuation { continuation in
                firebaseService.fetchRecords { result in
                    continuation.resume(with: result)
                }
            }
            
            records = result
            saveLocalRecords() // Cache the records locally
        } catch {
            self.error = error
            print("Error fetching records from Firebase: \(error)")
        }
    }
    
    // MARK: - Record Management
    
    func addRecord(_ record: Record) {
        records.append(record)
        saveLocalRecords()
        
        // Save to Firebase if user is logged in
        if Auth.auth().currentUser != nil {
            Task {
                do {
                    try await withCheckedThrowingContinuation { continuation in
                        firebaseService.saveRecord(record) { result in
                            continuation.resume(with: result)
                        }
                    }
                } catch {
                    self.error = error
                    print("Error saving record to Firebase: \(error)")
                }
            }
        }
    }
    
    func updateRecord(_ record: Record) {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
            saveLocalRecords()
            
            // Update in Firebase if user is logged in
            if Auth.auth().currentUser != nil {
                Task {
                    do {
                        try await withCheckedThrowingContinuation { continuation in
                            firebaseService.saveRecord(record) { result in
                                continuation.resume(with: result)
                            }
                        }
                    } catch {
                        self.error = error
                        print("Error updating record in Firebase: \(error)")
                    }
                }
            }
        }
    }
    
    func deleteRecord(_ record: Record) {
        records.removeAll { $0.id == record.id }
        saveLocalRecords()
        
        // Delete from Firebase if user is logged in
        if Auth.auth().currentUser != nil {
            Task {
                do {
                    try await withCheckedThrowingContinuation { continuation in
                        firebaseService.deleteRecord(id: record.id) { result in
                            continuation.resume(with: result)
                        }
                    }
                } catch {
                    self.error = error
                    print("Error deleting record from Firebase: \(error)")
                }
            }
        }
    }
    
    func incrementPlays(for record: Record) {
        if var record = records.first(where: { $0.id == record.id }) {
            record.incrementPlays()
            updateRecord(record)
        }
    }
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String) async throws -> User {
        try await withCheckedThrowingContinuation { continuation in
            firebaseService.signIn(email: email, password: password) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func signUp(email: String, password: String, username: String) async throws -> User {
        try await withCheckedThrowingContinuation { continuation in
            firebaseService.signUp(email: email, password: password, username: username) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func signOut() throws {
        try firebaseService.signOut()
        // Clear records after sign out
        records = []
        saveLocalRecords()
    }
    
    // MARK: - Filtering and Sorting
    
    func recordsByArtist() -> [String: [Record]] {
        Dictionary(grouping: records) { $0.artist }
            .mapValues { $0.sorted { $0.title < $1.title } }
    }
    
    func recordsByYear() -> [Int: [Record]] {
        Dictionary(grouping: records.filter { $0.year != nil }) { $0.year! }
            .mapValues { $0.sorted { $0.title < $1.title } }
    }
    
    func recordsByTag(_ tag: String) -> [Record] {
        records.filter { $0.tags.contains(tag.lowercased()) }
    }
    
    func mostPlayed(limit: Int = 10) -> [Record] {
        records.sorted { $0.plays > $1.plays }
            .prefix(limit)
            .map { $0 }
    }
    
    func recentlyPlayed(limit: Int = 10) -> [Record] {
        records.filter { $0.lastPlayed != nil }
            .sorted { $0.lastPlayed! > $1.lastPlayed! }
            .prefix(limit)
            .map { $0 }
    }
    
    func heavyRotation() -> [Record] {
        records.filter { $0.inHeavyRotation }
            .sorted { $0.plays > $1.plays }
    }
    
    // MARK: - Statistics
    
    var collectionStats: CollectionStats {
        let totalPlays = records.reduce(0) { $0 + $1.plays }
        let totalValue = records.reduce(0.0) { $0 + $1.value }
        
        let artistCounts = Dictionary(grouping: records) { $0.artist }
            .mapValues { $0.count }
        let topArtists = artistCounts.sorted { $0.value > $1.value }
            .prefix(10)
            .map { ($0.key, $0.value) }
        
        let yearDistribution = Dictionary(grouping: records.filter { $0.year != nil }) { 
            ($0.year! / 10) * 10 
        }.mapValues { $0.count }
        
        return CollectionStats(
            totalRecords: records.count,
            totalPlays: totalPlays,
            totalValue: totalValue,
            averagePlays: records.isEmpty ? 0 : Double(totalPlays) / Double(records.count),
            topArtists: topArtists,
            yearDistribution: yearDistribution
        )
    }
}

struct CollectionStats {
    let totalRecords: Int
    let totalPlays: Int
    let totalValue: Double
    let averagePlays: Double
    let topArtists: [(artist: String, count: Int)]
    let yearDistribution: [Int: Int]
    
    var formattedTotalValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: totalValue)) ?? "$0.00"
    }
}
