import XCTest
@testable import TooneMobile

final class MessageMapperTests: XCTestCase {

    // MARK: - Response Mapping

    func testMapFromResponse_withCompleteData_mapsAllFields() {
        let response = JSONRPCResponse(
            jsonrpc: "2.0",
            result: AnyCodable(dictionary: [
                "id": AnyCodable(string: "msg-123"),
                "role": AnyCodable(string: "assistant"),
                "content": AnyCodable(string: "Hello from the assistant"),
                "sessionId": AnyCodable(string: "session-abc")
            ]),
            error: nil,
            id: "req_1"
        )

        let message = MessageMapper.mapFromResponse(response)

        XCTAssertEqual(message.id, "msg-123")
        XCTAssertEqual(message.role, .assistant)
        XCTAssertEqual(message.status, .completed)
        XCTAssertEqual(message.sessionId, "session-abc")

        // Content should contain a text block
        XCTAssertEqual(message.content.count, 1)
        if case .text(let textContent) = message.content.first {
            XCTAssertEqual(textContent.text, "Hello from the assistant")
        } else {
            XCTFail("Expected text content")
        }
    }

    func testMapFromResponse_withMissingId_generatesUUID() {
        let response = JSONRPCResponse(
            jsonrpc: "2.0",
            result: AnyCodable(dictionary: [
                "role": AnyCodable(string: "user"),
                "content": AnyCodable(string: "Test")
            ]),
            error: nil,
            id: "req_2"
        )

        let message = MessageMapper.mapFromResponse(response)

        XCTAssertFalse(message.id.isEmpty, "Should generate a non-empty ID")
    }

    func testMapFromResponse_withUserRole_mapsRoleCorrectly() {
        let response = JSONRPCResponse(
            jsonrpc: "2.0",
            result: AnyCodable(dictionary: [
                "id": AnyCodable(string: "msg-u1"),
                "role": AnyCodable(string: "user"),
                "content": AnyCodable(string: "User message")
            ]),
            error: nil,
            id: "req_3"
        )

        let message = MessageMapper.mapFromResponse(response)

        XCTAssertEqual(message.role, .user)
    }

    func testMapFromResponse_withUnknownRole_defaultsToAssistant() {
        let response = JSONRPCResponse(
            jsonrpc: "2.0",
            result: AnyCodable(dictionary: [
                "id": AnyCodable(string: "msg-x1"),
                "role": AnyCodable(string: "unknown_role"),
                "content": AnyCodable(string: "Fallback")
            ]),
            error: nil,
            id: "req_4"
        )

        let message = MessageMapper.mapFromResponse(response)

        XCTAssertEqual(message.role, .assistant)
    }

    func testMapFromResponse_withNilResult_returnsDefaultMessage() {
        let response = JSONRPCResponse(
            jsonrpc: "2.0",
            result: nil,
            error: nil,
            id: "req_5"
        )

        let message = MessageMapper.mapFromResponse(response)

        XCTAssertFalse(message.id.isEmpty)
        XCTAssertEqual(message.role, .assistant)
        XCTAssertEqual(message.status, .completed)
    }

    func testMapFromResponse_withMissingSessionId_mapsToNilSession() {
        let response = JSONRPCResponse(
            jsonrpc: "2.0",
            result: AnyCodable(dictionary: [
                "id": AnyCodable(string: "msg-ns"),
                "content": AnyCodable(string: "No session")
            ]),
            error: nil,
            id: "req_6"
        )

        let message = MessageMapper.mapFromResponse(response)

        XCTAssertNil(message.sessionId)
    }

    // MARK: - Notification Mapping

    func testMapFromNotification_withCompleteData_mapsAllFields() {
        let notification = JSONRPCNotification(
            jsonrpc: "2.0",
            method: "chat.messageStream",
            params: AnyCodable(dictionary: [
                "id": AnyCodable(string: "msg-n1"),
                "role": AnyCodable(string: "assistant"),
                "content": AnyCodable(string: "Streaming response..."),
                "status": AnyCodable(string: "streaming"),
                "sessionId": AnyCodable(string: "session-n1")
            ])
        )

        let message = MessageMapper.mapFromNotification(notification)

        XCTAssertNotNil(message)
        XCTAssertEqual(message?.id, "msg-n1")
        XCTAssertEqual(message?.role, .assistant)
        XCTAssertEqual(message?.status, .streaming)
        XCTAssertEqual(message?.sessionId, "session-n1")
    }

    func testMapFromNotification_withNilParams_returnsNil() {
        let notification = JSONRPCNotification(
            jsonrpc: "2.0",
            method: "chat.messageStream",
            params: nil
        )

        let message = MessageMapper.mapFromNotification(notification)

        XCTAssertNil(message)
    }

    func testMapFromNotification_withCompletedStatus_mapsStatusCorrectly() {
        let notification = JSONRPCNotification(
            jsonrpc: "2.0",
            method: "chat.messageComplete",
            params: AnyCodable(dictionary: [
                "id": AnyCodable(string: "msg-c1"),
                "role": AnyCodable(string: "assistant"),
                "content": AnyCodable(string: "Done."),
                "status": AnyCodable(string: "completed")
            ])
        )

        let message = MessageMapper.mapFromNotification(notification)

        XCTAssertEqual(message?.status, .completed)
    }

    func testMapFromNotification_withFailedStatus_mapsStatusCorrectly() {
        let notification = JSONRPCNotification(
            jsonrpc: "2.0",
            method: "chat.messageStream",
            params: AnyCodable(dictionary: [
                "id": AnyCodable(string: "msg-f1"),
                "role": AnyCodable(string: "assistant"),
                "content": AnyCodable(string: "Error occurred"),
                "status": AnyCodable(string: "failed")
            ])
        )

        let message = MessageMapper.mapFromNotification(notification)

        XCTAssertEqual(message?.status, .failed)
    }

    // MARK: - Department Mapping

    func testDepartmentMapper_mapsFromResponse() {
        let response = JSONRPCResponse(
            jsonrpc: "2.0",
            result: AnyCodable(array: [
                AnyCodable(dictionary: [
                    "id": AnyCodable(string: "dept-1"),
                    "name": AnyCodable(string: "Engineering"),
                    "agents": AnyCodable(array: [
                        AnyCodable(dictionary: [
                            "id": AnyCodable(string: "agent-1"),
                            "name": AnyCodable(string: "Code Agent"),
                            "description": AnyCodable(string: "Writes code"),
                            "departmentId": AnyCodable(string: "dept-1"),
                            "isSystem": AnyCodable(bool: false)
                        ])
                    ])
                ])
            ]),
            error: nil,
            id: "req_d1"
        )

        let departments = DepartmentMapper.mapFromResponse(response)

        XCTAssertEqual(departments.count, 1)
        XCTAssertEqual(departments[0].id, "dept-1")
        XCTAssertEqual(departments[0].name, "Engineering")
        XCTAssertEqual(departments[0].agents.count, 1)
        XCTAssertEqual(departments[0].agents[0].id, "agent-1")
        XCTAssertEqual(departments[0].agents[0].name, "Code Agent")
    }

    // MARK: - Session Mapping

    func testSessionMapper_mapsFromResponse() {
        let response = JSONRPCResponse(
            jsonrpc: "2.0",
            result: AnyCodable(dictionary: [
                "id": AnyCodable(string: "sess-1"),
                "agentId": AnyCodable(string: "agent-1"),
                "agentName": AnyCodable(string: "Code Agent"),
                "messageCount": AnyCodable(int: 5),
                "isArchived": AnyCodable(bool: false)
            ]),
            error: nil,
            id: "req_s1"
        )

        let session = SessionMapper.mapFromResponse(response)

        XCTAssertEqual(session.id, "sess-1")
        XCTAssertEqual(session.agentId, "agent-1")
        XCTAssertEqual(session.agentName, "Code Agent")
        XCTAssertEqual(session.messageCount, 5)
        XCTAssertFalse(session.isArchived)
    }

    func testSessionMapper_mapsArrayFromResponse() {
        let response = JSONRPCResponse(
            jsonrpc: "2.0",
            result: AnyCodable(array: [
                AnyCodable(dictionary: [
                    "id": AnyCodable(string: "s1"),
                    "agentId": AnyCodable(string: "a1"),
                    "agentName": AnyCodable(string: "Agent A"),
                    "messageCount": AnyCodable(int: 3),
                    "isArchived": AnyCodable(bool: false)
                ]),
                AnyCodable(dictionary: [
                    "id": AnyCodable(string: "s2"),
                    "agentId": AnyCodable(string: "a2"),
                    "agentName": AnyCodable(string: "Agent B"),
                    "messageCount": AnyCodable(int: 7),
                    "isArchived": AnyCodable(bool: true)
                ])
            ]),
            error: nil,
            id: "req_sa"
        )

        let sessions = SessionMapper.mapArrayFromResponse(response)

        XCTAssertEqual(sessions.count, 2)
        XCTAssertEqual(sessions[0].id, "s1")
        XCTAssertEqual(sessions[1].id, "s2")
        XCTAssertTrue(sessions[1].isArchived)
    }

    // MARK: - ProjectFile Mapping

    func testProjectFileMapper_mapsFromResponse() {
        let response = JSONRPCResponse(
            jsonrpc: "2.0",
            result: AnyCodable(dictionary: [
                "id": AnyCodable(string: "root"),
                "name": AnyCodable(string: "project"),
                "path": AnyCodable(string: "/"),
                "isDirectory": AnyCodable(bool: true),
                "children": AnyCodable(array: [
                    AnyCodable(dictionary: [
                        "id": AnyCodable(string: "f1"),
                        "name": AnyCodable(string: "main.swift"),
                        "path": AnyCodable(string: "/main.swift"),
                        "isDirectory": AnyCodable(bool: false),
                        "size": AnyCodable(int: 1024)
                    ])
                ])
            ]),
            error: nil,
            id: "req_pf"
        )

        let file = ProjectFileMapper.mapFromResponse(response)

        XCTAssertEqual(file.name, "project")
        XCTAssertEqual(file.path, "/")
        XCTAssertTrue(file.isDirectory)
        XCTAssertEqual(file.children?.count, 1)
        XCTAssertEqual(file.children?[0].name, "main.swift")
        XCTAssertEqual(file.children?[0].size, 1024)
        XCTAssertFalse(file.children?[0].isDirectory ?? true)
    }
}
