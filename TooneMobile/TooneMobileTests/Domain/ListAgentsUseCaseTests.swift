import XCTest
@testable import TooneMobile

final class ListAgentsUseCaseTests: XCTestCase {

    private var mockAgentRepo: MockAgentRepository!
    private var sut: ListAgentsUseCase!

    override func setUp() {
        super.setUp()
        mockAgentRepo = MockAgentRepository()
        sut = ListAgentsUseCase(agentRepository: mockAgentRepo)
    }

    override func tearDown() {
        mockAgentRepo = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Returns Departments With Agents

    func test_execute_withDepartmentsAndAgents_returnsDepartments() async throws {
        // Arrange
        let agent1 = Agent(
            id: "agent-1",
            name: "Code Agent",
            description: "Writes code",
            departmentId: "dept-1",
            capabilities: ["code", "review"],
            routineNames: ["daily"],
            greeting: "Hello!",
            isSystem: false
        )
        let agent2 = Agent(
            id: "agent-2",
            name: "Test Agent",
            description: "Runs tests",
            departmentId: "dept-1",
            capabilities: ["test"],
            routineNames: [],
            greeting: nil,
            isSystem: false
        )
        let department = Department(
            id: "dept-1",
            name: "Engineering",
            agents: [agent1, agent2]
        )
        mockAgentRepo.stubbedDepartments = [department]

        // Act
        let result = try await sut.execute()

        // Assert
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].id, "dept-1")
        XCTAssertEqual(result[0].name, "Engineering")
        XCTAssertEqual(result[0].agents.count, 2)
        XCTAssertEqual(result[0].agents[0].name, "Code Agent")
        XCTAssertEqual(result[0].agents[1].name, "Test Agent")
        XCTAssertEqual(mockAgentRepo.listAgentsCallCount, 1)
    }

    func test_execute_withMultipleDepartments_returnsAll() async throws {
        // Arrange
        let dept1 = Department(
            id: "dept-1",
            name: "Engineering",
            agents: [
                Agent(id: "a1", name: "Agent A", description: "", departmentId: "dept-1",
                      capabilities: [], routineNames: [], greeting: nil, isSystem: false)
            ]
        )
        let dept2 = Department(
            id: "dept-2",
            name: "Design",
            agents: [
                Agent(id: "a2", name: "Agent B", description: "", departmentId: "dept-2",
                      capabilities: [], routineNames: [], greeting: nil, isSystem: false)
            ]
        )
        mockAgentRepo.stubbedDepartments = [dept1, dept2]

        // Act
        let result = try await sut.execute()

        // Assert
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, "dept-1")
        XCTAssertEqual(result[1].id, "dept-2")
    }

    // MARK: - Empty Result

    func test_execute_withNoDepartments_returnsEmptyArray() async throws {
        // Arrange
        mockAgentRepo.stubbedDepartments = []

        // Act
        let result = try await sut.execute()

        // Assert
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(mockAgentRepo.listAgentsCallCount, 1)
    }

    func test_execute_withEmptyAgentsInDepartment_returnsDepartmentWithNoAgents() async throws {
        // Arrange
        let emptyDept = Department(id: "dept-empty", name: "Empty", agents: [])
        mockAgentRepo.stubbedDepartments = [emptyDept]

        // Act
        let result = try await sut.execute()

        // Assert
        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(result[0].agents.isEmpty)
    }

    // MARK: - Error Propagation

    func test_execute_whenRepositoryThrows_propagatesError() async {
        // Arrange
        mockAgentRepo.listAgentsError = ConnectionError.unreachable

        // Act & Assert
        do {
            _ = try await sut.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? ConnectionError, .unreachable)
        }
    }

    // MARK: - Agent Updates Stream

    func test_agentUpdates_returnsStreamFromRepository() async {
        // Arrange
        let dept = Department(
            id: "dept-1",
            name: "Engineering",
            agents: [
                Agent(id: "a1", name: "Agent A", description: "", departmentId: "dept-1",
                      capabilities: [], routineNames: [], greeting: nil, isSystem: false)
            ]
        )
        let updatedDept = Department(
            id: "dept-1",
            name: "Engineering",
            agents: [
                Agent(id: "a1", name: "Agent A", description: "", departmentId: "dept-1",
                      capabilities: [], routineNames: [], greeting: nil, isSystem: false),
                Agent(id: "a2", name: "Agent B", description: "", departmentId: "dept-1",
                      capabilities: [], routineNames: [], greeting: nil, isSystem: false)
            ]
        )
        mockAgentRepo.stubbedAgentUpdates = [[dept], [updatedDept]]

        // Act
        let stream = sut.agentUpdates()
        var received: [[Department]] = []
        for await update in stream {
            received.append(update)
        }

        // Assert
        XCTAssertEqual(received.count, 2)
        XCTAssertEqual(received[0][0].agents.count, 1)
        XCTAssertEqual(received[1][0].agents.count, 2)
        XCTAssertEqual(mockAgentRepo.agentUpdatesCallCount, 1)
    }

    func test_agentUpdates_emptyStream_receivesNoUpdates() async {
        // Arrange
        mockAgentRepo.stubbedAgentUpdates = []

        // Act
        let stream = sut.agentUpdates()
        var received: [[Department]] = []
        for await update in stream {
            received.append(update)
        }

        // Assert
        XCTAssertTrue(received.isEmpty)
    }
}
