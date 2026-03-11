import SwiftData
import Foundation

// MARK: - PersistenceConfiguration

/// Configures the SwiftData model container for offline caching.
enum PersistenceConfiguration {

    /// Create a ModelContainer with the app's schema for production use.
    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            CachedMessage.self,
            CachedSession.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// Create an in-memory ModelContainer for previews and testing.
    static func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            CachedMessage.self,
            CachedSession.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
