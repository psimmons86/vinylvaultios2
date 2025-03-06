import Foundation
import Combine

// Wrapper class that conforms to ObservableObject
class DiscogsServiceWrapper: ObservableObject {
    let service: DiscogsService
    
    init(token: String) {
        self.service = DiscogsService(token: token)
    }
    
    func searchRecords(query: String) async throws -> [Record] {
        return try await service.searchRecords(query: query)
    }
    
    func getRecordDetails(releaseId: String) async throws -> Record {
        return try await service.getRecordDetails(releaseId: releaseId)
    }
}

enum DiscogsError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case apiError(String)
    case rateLimitExceeded
    case noInternetConnection
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .apiError(let message):
            return message
        case .rateLimitExceeded:
            return "Too many requests. Please try again in a moment."
        case .noInternetConnection:
            return "No internet connection. Please check your network settings."
        }
    }
}

actor DiscogsService {
    private let baseURL = "https://api.discogs.com"
    private let userAgent = "VinylVault/1.0 +https://github.com/example/vinylvault"
    private var token: String
    
    init(token: String) {
        self.token = token
    }
    
    private func createRequest(_ path: String, queryItems: [URLQueryItem] = []) throws -> URLRequest {
        // Add key and secret as query parameters instead of using Authorization header
        var allQueryItems = queryItems
        let keyParts = token.split(separator: ":")
        
        if keyParts.count == 2 {
            // Token is in format "key:secret"
            let key = String(keyParts[0])
            let secret = String(keyParts[1])
            
            // Add key as query parameter
            allQueryItems.append(URLQueryItem(name: "key", value: key))
            allQueryItems.append(URLQueryItem(name: "secret", value: secret))
        } else {
            // Fallback to using token directly
            allQueryItems.append(URLQueryItem(name: "token", value: token))
        }
        
        var components = URLComponents(string: baseURL + path)
        components?.queryItems = allQueryItems
        
        guard let url = components?.url else {
            throw DiscogsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        return request
    }
    
    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        #if DEBUG
        print("🌐 API Request: \(request.url?.absoluteString ?? "")")
        print("🔑 Headers: \(request.allHTTPHeaderFields ?? [:])")
        #endif
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                #if DEBUG
                print("❌ Invalid response type")
                #endif
                throw DiscogsError.apiError("Invalid response")
            }
            
            #if DEBUG
            print("📥 Status Code: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📦 Response: \(responseString)")
            }
            #endif
            
            if httpResponse.statusCode == 429 {
                // Rate limit exceeded, wait and retry
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                return try await performRequest(request)
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage: String
                if let errorData = String(data: data, encoding: .utf8) {
                    errorMessage = "HTTP \(httpResponse.statusCode): \(errorData)"
                } else {
                    errorMessage = "HTTP \(httpResponse.statusCode)"
                }
                #if DEBUG
                print("❌ API Error: \(errorMessage)")
                #endif
                throw DiscogsError.apiError(errorMessage)
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            #if DEBUG
            print("❌ Decoding error: \(error)")
            #endif
            throw DiscogsError.decodingError(error)
        } catch let error as URLError {
            #if DEBUG
            print("❌ URL error: \(error)")
            #endif
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw DiscogsError.noInternetConnection
            default:
                throw DiscogsError.networkError(error)
            }
        } catch {
            #if DEBUG
            print("❌ Unknown error: \(error)")
            #endif
            throw DiscogsError.networkError(error)
        }
    }
    
    // MARK: - Search Records
    
    struct SearchResult: Codable {
        let id: Int
        let title: String
        let year: String? // Year can be a string in the API response
        let thumb: String?
        let format: [String]?
    }
    
    struct SearchResponse: Codable {
        let results: [SearchResult]
    }
    
    func searchRecords(query: String) async throws -> [Record] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw DiscogsError.invalidURL
        }
        
        let queryItems = [
            URLQueryItem(name: "q", value: encodedQuery),
            URLQueryItem(name: "type", value: "release"),
            URLQueryItem(name: "format", value: "Vinyl"),
            URLQueryItem(name: "per_page", value: "40")
        ]
        
        let request = try createRequest("/database/search", queryItems: queryItems)
        let response: SearchResponse = try await performRequest(request)
        
        return response.results.map { result in
            let titleParts = result.title.split(separator: " - ")
            let artist = titleParts.count > 1 ? String(titleParts[0]) : "Unknown Artist"
            let title = titleParts.count > 1 ? String(titleParts[1]) : result.title
            
            let format: RecordFormat = {
                let formats = result.format?.first?.lowercased() ?? ""
                if formats.contains("single") { return .single }
                if formats.contains("ep") { return .ep }
                return .lp
            }()
            
            return Record(
                title: title.trimmingCharacters(in: .whitespaces),
                artist: artist.trimmingCharacters(in: .whitespaces),
                year: result.year,
                format: format,
                imageUrl: result.thumb ?? "default-album",
                discogsId: String(result.id)
            )
        }
    }
    
    // MARK: - Get Record Details
    
    struct ReleaseDetails: Codable {
        let title: String
        let artists: [Artist]?
        let year: Int?
        let genres: [String]?
        let styles: [String]?
        let formats: [Format]?
        let images: [Image]?
        
        struct Artist: Codable {
            let name: String
        }
        
        struct Format: Codable {
            let name: String?
        }
        
        struct Image: Codable {
            let resourceUrl: String
        }
    }
    
    func getRecordDetails(releaseId: String) async throws -> Record {
        let request = try createRequest("/releases/\(releaseId)")
        let release: ReleaseDetails = try await performRequest(request)
        
        let titleParts = release.title.split(separator: " - ")
        let artist = release.artists?.first?.name ?? 
                    (titleParts.count > 1 ? String(titleParts[0]) : "Unknown Artist")
        let title = titleParts.count > 1 ? String(titleParts[1]) : release.title
        
        let format: RecordFormat = {
            let formatName = release.formats?.first?.name?.lowercased() ?? ""
            if formatName.contains("single") { return .single }
            if formatName.contains("ep") { return .ep }
            return .lp
        }()
        
        var tags = Set<String>()
        
        // Process genres
        if let genres = release.genres {
            for genre in genres {
                let processedGenre = genre.count > 50 ? String(genre.prefix(50)) : genre
                tags.insert(processedGenre.lowercased())
            }
        }
        
        // Process styles
        if let styles = release.styles {
            for style in styles {
                let processedStyle = style.count > 50 ? String(style.prefix(50)) : style
                tags.insert(processedStyle.lowercased())
            }
        }
        
        return Record(
            title: title.trimmingCharacters(in: .whitespaces),
            artist: artist.trimmingCharacters(in: .whitespaces),
            year: release.year,
            format: format,
            tags: Array(tags),
            imageUrl: release.images?.first?.resourceUrl ?? "default-album",
            discogsId: releaseId
        )
    }
}
