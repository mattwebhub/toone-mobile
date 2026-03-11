import Foundation

// MARK: - DepartmentMapper

/// Maps between Department/Agent JSON-RPC data and Domain entities.
enum DepartmentMapper {

    // MARK: - Response -> Domain

    /// Parse an array of Departments from a JSON-RPC response.
    static func mapFromResponse(_ response: JSONRPCResponse) -> [Department] {
        guard let items = response.result?.arrayValue else {
            // Also handle wrapped format: { "departments": [...] }
            if let dict = response.result?.dictionaryValue,
               let items = dict["departments"]?.arrayValue {
                return items.compactMap { mapDepartment(from: $0) }
            }
            return []
        }
        return items.compactMap { mapDepartment(from: $0) }
    }

    // MARK: - Notification -> Domain

    /// Parse an array of Departments from a JSON-RPC notification.
    static func mapFromNotification(_ notification: JSONRPCNotification) -> [Department] {
        guard let dict = notification.params?.dictionaryValue,
              let items = dict["departments"]?.arrayValue else { return [] }
        return items.compactMap { mapDepartment(from: $0) }
    }

    // MARK: - AnyCodable Array -> Domain

    /// Parse Departments from an optional AnyCodable array.
    static func mapFromAnyCodableArray(_ value: AnyCodable?) -> [Department] {
        guard let items = value?.arrayValue else { return [] }
        return items.compactMap { mapDepartment(from: $0) }
    }

    // MARK: - Private

    private static func mapDepartment(from value: AnyCodable) -> Department? {
        guard let dict = value.dictionaryValue,
              let id = dict["id"]?.stringValue,
              let name = dict["name"]?.stringValue else { return nil }
        let agents = (dict["agents"]?.arrayValue ?? []).compactMap { mapAgent(from: $0) }
        return Department(id: id, name: name, agents: agents)
    }

    private static func mapAgent(from value: AnyCodable) -> Agent? {
        guard let dict = value.dictionaryValue,
              let id = dict["id"]?.stringValue,
              let name = dict["name"]?.stringValue else { return nil }
        return Agent(
            id: id,
            name: name,
            description: dict["description"]?.stringValue ?? "",
            departmentId: dict["departmentId"]?.stringValue ?? "",
            capabilities: dict["capabilities"]?.arrayValue?.compactMap(\.stringValue) ?? [],
            routineNames: dict["routineNames"]?.arrayValue?.compactMap(\.stringValue) ?? [],
            greeting: dict["greeting"]?.stringValue,
            isSystem: dict["isSystem"]?.boolValue ?? false,
            sessionId: dict["sessionId"]?.stringValue
        )
    }
}

// MARK: - AgentMapper

/// Convenience mapper for individual Agent instances.
enum AgentMapper {

    /// Parse a single Agent from an AnyCodable dictionary.
    static func mapFromAnyCodable(_ value: AnyCodable?) -> Agent? {
        guard let dict = value?.dictionaryValue,
              let id = dict["id"]?.stringValue,
              let name = dict["name"]?.stringValue else {
            return nil
        }

        return Agent(
            id: id,
            name: name,
            description: dict["description"]?.stringValue ?? "",
            departmentId: dict["departmentId"]?.stringValue ?? "",
            capabilities: dict["capabilities"]?.arrayValue?.compactMap(\.stringValue) ?? [],
            routineNames: dict["routineNames"]?.arrayValue?.compactMap(\.stringValue) ?? [],
            greeting: dict["greeting"]?.stringValue,
            isSystem: dict["isSystem"]?.boolValue ?? false,
            sessionId: dict["sessionId"]?.stringValue
        )
    }

    /// Convert a Domain Agent to an AgentDTO.
    static func toDTO(_ agent: Agent) -> AgentDTO {
        AgentDTO(
            id: agent.id,
            name: agent.name,
            description: agent.description,
            departmentId: agent.departmentId,
            capabilities: agent.capabilities,
            routineNames: agent.routineNames,
            greeting: agent.greeting,
            isSystem: agent.isSystem,
            sessionId: agent.sessionId
        )
    }

    /// Convert a Domain Department to a DepartmentDTO.
    static func departmentToDTO(_ department: Department) -> DepartmentDTO {
        DepartmentDTO(
            id: department.id,
            name: department.name,
            agents: department.agents.map { toDTO($0) }
        )
    }
}

// MARK: - SessionMapper

/// Maps between Session JSON-RPC data and Domain entities.
enum SessionMapper {

    private nonisolated(unsafe) static let iso8601 = ISO8601DateFormatter()

    // MARK: - Response -> Domain (Single)

    /// Parse a single Session from a JSON-RPC response result.
    static func mapFromResponse(_ response: JSONRPCResponse) -> Session {
        let dict = response.result?.dictionaryValue ?? [:]
        return mapSession(from: dict)
    }

    // MARK: - Response -> Domain (Array)

    /// Parse an array of Sessions from a JSON-RPC response result.
    static func mapArrayFromResponse(_ response: JSONRPCResponse) -> [Session] {
        guard let items = response.result?.arrayValue else {
            // Also handle wrapped format: { "sessions": [...] }
            if let dict = response.result?.dictionaryValue,
               let items = dict["sessions"]?.arrayValue {
                return items.compactMap { item in
                    guard let d = item.dictionaryValue else { return nil }
                    return mapSession(from: d)
                }
            }
            return []
        }
        return items.compactMap { item in
            guard let dict = item.dictionaryValue else { return nil }
            return mapSession(from: dict)
        }
    }

    // MARK: - Notification -> Domain (Array)

    /// Parse an array of Sessions from a JSON-RPC notification.
    static func mapArrayFromNotification(_ notification: JSONRPCNotification) -> [Session] {
        guard let dict = notification.params?.dictionaryValue,
              let items = dict["sessions"]?.arrayValue else { return [] }
        return items.compactMap { item in
            guard let d = item.dictionaryValue else { return nil }
            return mapSession(from: d)
        }
    }

    // MARK: - AnyCodable Array -> Domain

    /// Parse Sessions from an optional AnyCodable array.
    static func mapFromAnyCodableArray(_ value: AnyCodable?) -> [Session] {
        guard let items = value?.arrayValue else { return [] }
        return items.compactMap { item in
            guard let dict = item.dictionaryValue else { return nil }
            return mapSession(from: dict)
        }
    }

    // MARK: - Private

    private static func mapSession(from dict: [String: AnyCodable]) -> Session {
        Session(
            id: dict["id"]?.stringValue ?? UUID().uuidString,
            agentId: dict["agentId"]?.stringValue ?? "",
            agentName: dict["agentName"]?.stringValue ?? "",
            startedAt: dict["startedAt"]?.stringValue.flatMap { iso8601.date(from: $0) } ?? Date(),
            lastInteractionAt: dict["lastInteractionAt"]?.stringValue.flatMap { iso8601.date(from: $0) } ?? Date(),
            messageCount: dict["messageCount"]?.intValue ?? 0,
            lastMessagePreview: dict["lastMessagePreview"]?.stringValue,
            isArchived: dict["isArchived"]?.boolValue ?? false
        )
    }
}

// MARK: - ProjectFileMapper

/// Maps between ProjectFile JSON-RPC data and Domain entities.
enum ProjectFileMapper {

    // MARK: - Response -> Domain

    /// Parse a ProjectFile tree from a JSON-RPC response result.
    static func mapFromResponse(_ response: JSONRPCResponse) -> ProjectFile {
        guard let dict = response.result?.dictionaryValue else {
            return ProjectFile(
                id: UUID().uuidString, name: "root", path: "/",
                isDirectory: true, children: nil, size: nil, modifiedAt: nil
            )
        }
        return mapFile(from: dict)
    }

    // MARK: - Notification -> Domain

    /// Parse a ProjectFile tree from a JSON-RPC notification.
    static func mapFromNotification(_ notification: JSONRPCNotification) -> ProjectFile? {
        guard let dict = notification.params?.dictionaryValue,
              let tree = dict["projectTree"]?.dictionaryValue else { return nil }
        return mapFile(from: tree)
    }

    // MARK: - AnyCodable -> Domain

    /// Parse a ProjectFile tree from an optional AnyCodable value.
    static func mapFromAnyCodable(_ value: AnyCodable?) -> ProjectFile? {
        guard let dict = value?.dictionaryValue else { return nil }
        return mapFile(from: dict)
    }

    // MARK: - Private

    private static func mapFile(from dict: [String: AnyCodable]) -> ProjectFile {
        let children = dict["children"]?.arrayValue?.compactMap { child -> ProjectFile? in
            guard let childDict = child.dictionaryValue else { return nil }
            return mapFile(from: childDict)
        }
        let iso8601 = ISO8601DateFormatter()
        return ProjectFile(
            id: dict["id"]?.stringValue ?? UUID().uuidString,
            name: dict["name"]?.stringValue ?? "",
            path: dict["path"]?.stringValue ?? "",
            isDirectory: dict["isDirectory"]?.boolValue ?? false,
            children: children?.isEmpty == true ? nil : children,
            size: dict["size"]?.intValue,
            modifiedAt: dict["modifiedAt"]?.stringValue.flatMap { iso8601.date(from: $0) }
        )
    }
}
