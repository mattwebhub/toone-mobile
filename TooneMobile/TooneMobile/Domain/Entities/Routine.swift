import Foundation

// MARK: - Routine

public struct Routine: Identifiable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let departmentId: String
    public let agentName: String
    public let purpose: String
    public let cadence: RoutineCadence

    public init(
        id: String,
        name: String,
        departmentId: String,
        agentName: String,
        purpose: String,
        cadence: RoutineCadence
    ) {
        self.id = id
        self.name = name
        self.departmentId = departmentId
        self.agentName = agentName
        self.purpose = purpose
        self.cadence = cadence
    }
}

// MARK: - RoutineCadence

public enum RoutineCadence: String, Sendable, Codable, Equatable {
    case daily
    case weekly
    case biWeekly
    case onDemand
}
