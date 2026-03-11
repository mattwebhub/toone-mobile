import XCTest
@testable import TooneMobile

final class AgentMapperTests: XCTestCase {

    // MARK: - AgentDTO -> Domain

    func test_toDomain_agent_withCompleteDTO_mapsAllFields() {
        // Arrange
        let dto = AgentDTO(
            id: "agent-1",
            name: "Code Agent",
            description: "Writes code",
            departmentId: "dept-1",
            capabilities: ["code", "review"],
            routineNames: ["daily", "weekly"],
            greeting: "Hello!",
            isSystem: false,
            sessionId: "session-1"
        )

        // Act
        let agent = AgentMapper.toDomain(dto)

        // Assert
        XCTAssertEqual(agent.id, "agent-1")
        XCTAssertEqual(agent.name, "Code Agent")
        XCTAssertEqual(agent.description, "Writes code")
        XCTAssertEqual(agent.departmentId, "dept-1")
        XCTAssertEqual(agent.capabilities, ["code", "review"])
        XCTAssertEqual(agent.routineNames, ["daily", "weekly"])
        XCTAssertEqual(agent.greeting, "Hello!")
        XCTAssertFalse(agent.isSystem)
        XCTAssertEqual(agent.sessionId, "session-1")
    }

    func test_toDomain_agent_withNilOptionalFields_defaultsCorrectly() {
        // Arrange
        let dto = AgentDTO(
            id: "agent-2",
            name: "Minimal Agent",
            description: "Minimal",
            departmentId: "dept-1",
            capabilities: nil,
            routineNames: nil,
            greeting: nil,
            isSystem: nil,
            sessionId: nil
        )

        // Act
        let agent = AgentMapper.toDomain(dto)

        // Assert
        XCTAssertEqual(agent.capabilities, [])
        XCTAssertEqual(agent.routineNames, [])
        XCTAssertNil(agent.greeting)
        XCTAssertFalse(agent.isSystem)
        XCTAssertNil(agent.sessionId)
    }

    func test_toDomain_agent_withSystemFlag_mapsIsSystemTrue() {
        // Arrange
        let dto = AgentDTO(
            id: "agent-sys",
            name: "System Agent",
            description: "System-level agent",
            departmentId: "dept-sys",
            capabilities: ["admin"],
            routineNames: nil,
            greeting: nil,
            isSystem: true,
            sessionId: nil
        )

        // Act
        let agent = AgentMapper.toDomain(dto)

        // Assert
        XCTAssertTrue(agent.isSystem)
    }

    // MARK: - DepartmentDTO -> Domain

    func test_toDomain_department_withAgents_mapsAllFields() {
        // Arrange
        let agentDTO = AgentDTO(
            id: "a1", name: "Agent A", description: "Desc A",
            departmentId: "dept-1", capabilities: ["cap1"],
            routineNames: ["r1"], greeting: "Hi", isSystem: false, sessionId: nil
        )
        let dto = DepartmentDTO(id: "dept-1", name: "Engineering", agents: [agentDTO])

        // Act
        let department = AgentMapper.toDomain(dto)

        // Assert
        XCTAssertEqual(department.id, "dept-1")
        XCTAssertEqual(department.name, "Engineering")
        XCTAssertEqual(department.agents.count, 1)
        XCTAssertEqual(department.agents[0].id, "a1")
        XCTAssertEqual(department.agents[0].name, "Agent A")
    }

    func test_toDomain_department_withNilAgents_returnsEmptyAgentsList() {
        // Arrange
        let dto = DepartmentDTO(id: "dept-empty", name: "Empty Dept", agents: nil)

        // Act
        let department = AgentMapper.toDomain(dto)

        // Assert
        XCTAssertEqual(department.id, "dept-empty")
        XCTAssertTrue(department.agents.isEmpty)
    }

    func test_toDomain_department_withMultipleAgents_mapsAll() {
        // Arrange
        let agents = [
            AgentDTO(id: "a1", name: "Agent 1", description: "D1", departmentId: "d1",
                     capabilities: nil, routineNames: nil, greeting: nil, isSystem: nil, sessionId: nil),
            AgentDTO(id: "a2", name: "Agent 2", description: "D2", departmentId: "d1",
                     capabilities: nil, routineNames: nil, greeting: nil, isSystem: nil, sessionId: nil),
            AgentDTO(id: "a3", name: "Agent 3", description: "D3", departmentId: "d1",
                     capabilities: nil, routineNames: nil, greeting: nil, isSystem: nil, sessionId: nil)
        ]
        let dto = DepartmentDTO(id: "d1", name: "Team", agents: agents)

        // Act
        let department = AgentMapper.toDomain(dto)

        // Assert
        XCTAssertEqual(department.agents.count, 3)
        XCTAssertEqual(department.agents[0].id, "a1")
        XCTAssertEqual(department.agents[1].id, "a2")
        XCTAssertEqual(department.agents[2].id, "a3")
    }

    // MARK: - Domain -> AgentDTO

    func test_toDTO_agent_mapsAllFields() {
        // Arrange
        let agent = Agent(
            id: "agent-1",
            name: "Code Agent",
            description: "Writes code",
            departmentId: "dept-1",
            capabilities: ["code"],
            routineNames: ["daily"],
            greeting: "Hello!",
            isSystem: false,
            sessionId: "s1"
        )

        // Act
        let dto = AgentMapper.toDTO(agent)

        // Assert
        XCTAssertEqual(dto.id, "agent-1")
        XCTAssertEqual(dto.name, "Code Agent")
        XCTAssertEqual(dto.description, "Writes code")
        XCTAssertEqual(dto.departmentId, "dept-1")
        XCTAssertEqual(dto.capabilities, ["code"])
        XCTAssertEqual(dto.routineNames, ["daily"])
        XCTAssertEqual(dto.greeting, "Hello!")
        XCTAssertEqual(dto.isSystem, false)
        XCTAssertEqual(dto.sessionId, "s1")
    }

    func test_toDTO_agent_withNilOptionals_mapsNils() {
        // Arrange
        let agent = Agent(
            id: "a1", name: "Agent", description: "",
            departmentId: "d1", capabilities: [],
            routineNames: [], greeting: nil, isSystem: false, sessionId: nil
        )

        // Act
        let dto = AgentMapper.toDTO(agent)

        // Assert
        XCTAssertNil(dto.greeting)
        XCTAssertNil(dto.sessionId)
    }

    // MARK: - Domain -> DepartmentDTO

    func test_toDTO_department_mapsAllFields() {
        // Arrange
        let agent = Agent(
            id: "a1", name: "Agent A", description: "Desc",
            departmentId: "dept-1", capabilities: [],
            routineNames: [], greeting: nil, isSystem: false
        )
        let department = Department(id: "dept-1", name: "Engineering", agents: [agent])

        // Act
        let dto = AgentMapper.toDTO(department)

        // Assert
        XCTAssertEqual(dto.id, "dept-1")
        XCTAssertEqual(dto.name, "Engineering")
        XCTAssertEqual(dto.agents?.count, 1)
        XCTAssertEqual(dto.agents?[0].id, "a1")
    }

    func test_toDTO_department_withEmptyAgents_mapsEmptyArray() {
        // Arrange
        let department = Department(id: "d1", name: "Empty", agents: [])

        // Act
        let dto = AgentMapper.toDTO(department)

        // Assert
        XCTAssertEqual(dto.agents?.count, 0)
    }

    // MARK: - Round-trip DTO -> Domain -> DTO

    func test_roundTrip_agentDTO_toDomainAndBack_preservesFields() {
        // Arrange
        let originalDTO = AgentDTO(
            id: "agent-rt",
            name: "Round Trip Agent",
            description: "Tests round trip",
            departmentId: "dept-rt",
            capabilities: ["cap1", "cap2"],
            routineNames: ["r1"],
            greeting: "Greetings!",
            isSystem: true,
            sessionId: "session-rt"
        )

        // Act
        let domain = AgentMapper.toDomain(originalDTO)
        let backToDTO = AgentMapper.toDTO(domain)

        // Assert
        XCTAssertEqual(backToDTO.id, originalDTO.id)
        XCTAssertEqual(backToDTO.name, originalDTO.name)
        XCTAssertEqual(backToDTO.description, originalDTO.description)
        XCTAssertEqual(backToDTO.departmentId, originalDTO.departmentId)
        XCTAssertEqual(backToDTO.capabilities, originalDTO.capabilities)
        XCTAssertEqual(backToDTO.routineNames, originalDTO.routineNames)
        XCTAssertEqual(backToDTO.greeting, originalDTO.greeting)
        XCTAssertEqual(backToDTO.isSystem, originalDTO.isSystem)
        XCTAssertEqual(backToDTO.sessionId, originalDTO.sessionId)
    }

    func test_roundTrip_departmentDTO_toDomainAndBack_preservesFields() {
        // Arrange
        let agentDTO = AgentDTO(
            id: "a1", name: "Agent", description: "D",
            departmentId: "d1", capabilities: ["c"],
            routineNames: [], greeting: nil, isSystem: false, sessionId: nil
        )
        let originalDTO = DepartmentDTO(id: "d1", name: "Dept", agents: [agentDTO])

        // Act
        let domain = AgentMapper.toDomain(originalDTO)
        let backToDTO = AgentMapper.toDTO(domain)

        // Assert
        XCTAssertEqual(backToDTO.id, originalDTO.id)
        XCTAssertEqual(backToDTO.name, originalDTO.name)
        XCTAssertEqual(backToDTO.agents?.count, originalDTO.agents?.count)
        XCTAssertEqual(backToDTO.agents?[0].id, originalDTO.agents?[0].id)
    }

    // MARK: - AnyCodable -> Domain

    func test_agentFromAnyCodable_withCompleteDict_returnsAgent() {
        // Arrange
        let value = AnyCodable(dictionary: [
            "id": AnyCodable(string: "agent-ac"),
            "name": AnyCodable(string: "AC Agent"),
            "description": AnyCodable(string: "From AnyCodable"),
            "departmentId": AnyCodable(string: "dept-ac"),
            "capabilities": AnyCodable(array: [AnyCodable(string: "cap1")]),
            "routineNames": AnyCodable(array: [AnyCodable(string: "r1")]),
            "greeting": AnyCodable(string: "Hey"),
            "isSystem": AnyCodable(bool: true),
            "sessionId": AnyCodable(string: "s-ac")
        ])

        // Act
        let agent = AgentMapper.agentFromAnyCodable(value)

        // Assert
        XCTAssertNotNil(agent)
        XCTAssertEqual(agent?.id, "agent-ac")
        XCTAssertEqual(agent?.name, "AC Agent")
        XCTAssertEqual(agent?.capabilities, ["cap1"])
        XCTAssertTrue(agent?.isSystem ?? false)
    }

    func test_agentFromAnyCodable_withMissingId_returnsNil() {
        // Arrange
        let value = AnyCodable(dictionary: [
            "name": AnyCodable(string: "No ID")
        ])

        // Act
        let agent = AgentMapper.agentFromAnyCodable(value)

        // Assert
        XCTAssertNil(agent)
    }

    func test_agentFromAnyCodable_withMissingName_returnsNil() {
        // Arrange
        let value = AnyCodable(dictionary: [
            "id": AnyCodable(string: "agent-1")
        ])

        // Act
        let agent = AgentMapper.agentFromAnyCodable(value)

        // Assert
        XCTAssertNil(agent)
    }

    func test_departmentFromAnyCodable_withCompleteDict_returnsDepartment() {
        // Arrange
        let value = AnyCodable(dictionary: [
            "id": AnyCodable(string: "dept-ac"),
            "name": AnyCodable(string: "Engineering"),
            "agents": AnyCodable(array: [
                AnyCodable(dictionary: [
                    "id": AnyCodable(string: "a1"),
                    "name": AnyCodable(string: "Agent 1"),
                    "description": AnyCodable(string: ""),
                    "departmentId": AnyCodable(string: "dept-ac")
                ])
            ])
        ])

        // Act
        let department = AgentMapper.departmentFromAnyCodable(value)

        // Assert
        XCTAssertNotNil(department)
        XCTAssertEqual(department?.id, "dept-ac")
        XCTAssertEqual(department?.name, "Engineering")
        XCTAssertEqual(department?.agents.count, 1)
    }

    func test_departmentFromAnyCodable_withMissingId_returnsNil() {
        // Arrange
        let value = AnyCodable(dictionary: [
            "name": AnyCodable(string: "No ID Dept")
        ])

        // Act
        let department = AgentMapper.departmentFromAnyCodable(value)

        // Assert
        XCTAssertNil(department)
    }

    func test_departmentFromAnyCodable_withNoAgents_returnsEmptyAgentsList() {
        // Arrange
        let value = AnyCodable(dictionary: [
            "id": AnyCodable(string: "dept-no-agents"),
            "name": AnyCodable(string: "Lonely Dept")
        ])

        // Act
        let department = AgentMapper.departmentFromAnyCodable(value)

        // Assert
        XCTAssertNotNil(department)
        XCTAssertTrue(department?.agents.isEmpty ?? false)
    }
}
