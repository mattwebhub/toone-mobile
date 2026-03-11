import XCTest
@testable import TooneMobile

final class TunnelProtocolTests: XCTestCase {

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Request Serialization

    func testJSONRPCRequest_encodesToValidJSON() throws {
        let request = JSONRPCRequest(
            method: "chat.sendMessage",
            params: AnyCodable(dictionary: [
                "content": AnyCodable(string: "Hello"),
                "agentId": AnyCodable(string: "agent-1")
            ]),
            id: "req_1"
        )

        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json)
        XCTAssertEqual(json?["jsonrpc"] as? String, "2.0")
        XCTAssertEqual(json?["method"] as? String, "chat.sendMessage")
        XCTAssertEqual(json?["id"] as? String, "req_1")

        let params = json?["params"] as? [String: Any]
        XCTAssertEqual(params?["content"] as? String, "Hello")
        XCTAssertEqual(params?["agentId"] as? String, "agent-1")
    }

    func testJSONRPCRequest_withNilParams_encodesWithoutParams() throws {
        let request = JSONRPCRequest(method: "connection.ping", id: "req_2")

        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["method"] as? String, "connection.ping")
        // params should be null or absent
        if let params = json?["params"] {
            XCTAssertTrue(params is NSNull, "params should be null when not provided")
        }
    }

    func testJSONRPCRequest_preservesProtocolVersion() throws {
        let request = JSONRPCRequest(method: "auth.handshake", id: "req_3")

        let data = try encoder.encode(request)
        let decoded = try decoder.decode(JSONRPCRequest.self, from: data)

        XCTAssertEqual(decoded.jsonrpc, "2.0")
        XCTAssertEqual(decoded.method, "auth.handshake")
        XCTAssertEqual(decoded.id, "req_3")
    }

    // MARK: - Response Deserialization

    func testJSONRPCResponse_decodesSuccessResponse() throws {
        let json = """
        {
            "jsonrpc": "2.0",
            "result": {"status": "ok", "version": "1.2.3"},
            "id": "req_1"
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(JSONRPCResponse.self, from: json)

        XCTAssertEqual(response.jsonrpc, "2.0")
        XCTAssertEqual(response.id, "req_1")
        XCTAssertNil(response.error)
        XCTAssertNotNil(response.result)
        XCTAssertEqual(response.result?["status"]?.stringValue, "ok")
        XCTAssertEqual(response.result?["version"]?.stringValue, "1.2.3")
    }

    func testJSONRPCResponse_decodesNullResult() throws {
        let json = """
        {
            "jsonrpc": "2.0",
            "result": null,
            "id": "req_2"
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(JSONRPCResponse.self, from: json)

        XCTAssertEqual(response.id, "req_2")
        XCTAssertNil(response.error)
        // result is an AnyCodable wrapping null
        XCTAssertTrue(response.result?.isNull ?? true)
    }

    func testJSONRPCResponse_decodesNumericResult() throws {
        let json = """
        {
            "jsonrpc": "2.0",
            "result": 42,
            "id": "req_3"
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(JSONRPCResponse.self, from: json)

        XCTAssertEqual(response.result?.intValue, 42)
    }

    // MARK: - Error Handling

    func testJSONRPCResponse_decodesErrorResponse() throws {
        let json = """
        {
            "jsonrpc": "2.0",
            "error": {
                "code": -32001,
                "message": "Authentication failed",
                "data": null
            },
            "id": "req_4"
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(JSONRPCResponse.self, from: json)

        XCTAssertEqual(response.id, "req_4")
        XCTAssertNil(response.result)
        XCTAssertNotNil(response.error)
        XCTAssertEqual(response.error?.code, -32001)
        XCTAssertEqual(response.error?.message, "Authentication failed")
    }

    func testJSONRPCResponse_decodesErrorWithData() throws {
        let json = """
        {
            "jsonrpc": "2.0",
            "error": {
                "code": -32602,
                "message": "Invalid params",
                "data": {"field": "agentId", "reason": "not found"}
            },
            "id": "req_5"
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(JSONRPCResponse.self, from: json)

        XCTAssertEqual(response.error?.code, TunnelErrorCode.invalidParams.rawValue)
        XCTAssertEqual(response.error?.data?["field"]?.stringValue, "agentId")
        XCTAssertEqual(response.error?.data?["reason"]?.stringValue, "not found")
    }

    func testTunnelErrorCode_mapsStandardCodes() {
        XCTAssertEqual(TunnelErrorCode.parseError.rawValue, -32700)
        XCTAssertEqual(TunnelErrorCode.invalidRequest.rawValue, -32600)
        XCTAssertEqual(TunnelErrorCode.methodNotFound.rawValue, -32601)
        XCTAssertEqual(TunnelErrorCode.invalidParams.rawValue, -32602)
        XCTAssertEqual(TunnelErrorCode.internalError.rawValue, -32603)
    }

    func testTunnelErrorCode_mapsCustomCodes() {
        XCTAssertEqual(TunnelErrorCode.authRequired.rawValue, -32000)
        XCTAssertEqual(TunnelErrorCode.authFailed.rawValue, -32001)
        XCTAssertEqual(TunnelErrorCode.sessionNotFound.rawValue, -32002)
        XCTAssertEqual(TunnelErrorCode.agentNotFound.rawValue, -32003)
        XCTAssertEqual(TunnelErrorCode.fileNotFound.rawValue, -32004)
        XCTAssertEqual(TunnelErrorCode.desktopBusy.rawValue, -32005)
    }

    // MARK: - Notification Parsing

    func testJSONRPCNotification_decodesNotification() throws {
        let json = """
        {
            "jsonrpc": "2.0",
            "method": "chat.messageStream",
            "params": {
                "id": "msg-42",
                "role": "assistant",
                "content": "Processing your request...",
                "status": "streaming"
            }
        }
        """.data(using: .utf8)!

        let notification = try decoder.decode(JSONRPCNotification.self, from: json)

        XCTAssertEqual(notification.jsonrpc, "2.0")
        XCTAssertEqual(notification.method, "chat.messageStream")
        XCTAssertNotNil(notification.params)
        XCTAssertEqual(notification.params?["id"]?.stringValue, "msg-42")
        XCTAssertEqual(notification.params?["role"]?.stringValue, "assistant")
        XCTAssertEqual(notification.params?["content"]?.stringValue, "Processing your request...")
        XCTAssertEqual(notification.params?["status"]?.stringValue, "streaming")
    }

    func testJSONRPCNotification_decodesWithoutParams() throws {
        let json = """
        {
            "jsonrpc": "2.0",
            "method": "connection.status"
        }
        """.data(using: .utf8)!

        let notification = try decoder.decode(JSONRPCNotification.self, from: json)

        XCTAssertEqual(notification.method, "connection.status")
        XCTAssertNil(notification.params)
    }

    func testJSONRPCNotification_decodesToolCallNotification() throws {
        let json = """
        {
            "jsonrpc": "2.0",
            "method": "chat.toolCall",
            "params": {
                "id": "tc-1",
                "name": "readFile",
                "status": "executing",
                "input": "{\\"path\\": \\"/src/main.swift\\"}"
            }
        }
        """.data(using: .utf8)!

        let notification = try decoder.decode(JSONRPCNotification.self, from: json)

        XCTAssertEqual(notification.method, "chat.toolCall")
        XCTAssertEqual(notification.params?["name"]?.stringValue, "readFile")
        XCTAssertEqual(notification.params?["status"]?.stringValue, "executing")
    }

    // MARK: - TunnelMethod Raw Values

    func testTunnelMethod_rawValues() {
        XCTAssertEqual(TunnelMethod.authHandshake.rawValue, "auth.handshake")
        XCTAssertEqual(TunnelMethod.chatSendMessage.rawValue, "chat.sendMessage")
        XCTAssertEqual(TunnelMethod.chatMessageStream.rawValue, "chat.messageStream")
        XCTAssertEqual(TunnelMethod.agentList.rawValue, "agent.list")
        XCTAssertEqual(TunnelMethod.agentSwitch.rawValue, "agent.switch")
        XCTAssertEqual(TunnelMethod.sessionList.rawValue, "session.list")
        XCTAssertEqual(TunnelMethod.projectTree.rawValue, "project.tree")
        XCTAssertEqual(TunnelMethod.connectionPing.rawValue, "connection.ping")
    }

    // MARK: - Round-trip Encoding/Decoding

    func testJSONRPCRequest_roundTrip() throws {
        let original = JSONRPCRequest(
            method: "agent.list",
            params: AnyCodable(dictionary: ["filter": AnyCodable(string: "active")]),
            id: "req_rt"
        )

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(JSONRPCRequest.self, from: data)

        XCTAssertEqual(decoded.jsonrpc, original.jsonrpc)
        XCTAssertEqual(decoded.method, original.method)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.params?["filter"]?.stringValue, "active")
    }

    // MARK: - AnyCodable Round-Trip

    func testAnyCodable_roundTrip_string() throws {
        let original = AnyCodable(string: "hello")
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(AnyCodable.self, from: data)

        XCTAssertEqual(decoded.stringValue, "hello")
    }

    func testAnyCodable_roundTrip_int() throws {
        let original = AnyCodable(int: 42)
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(AnyCodable.self, from: data)

        XCTAssertEqual(decoded.intValue, 42)
    }

    func testAnyCodable_roundTrip_bool() throws {
        let original = AnyCodable(bool: true)
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(AnyCodable.self, from: data)

        XCTAssertEqual(decoded.boolValue, true)
    }

    func testAnyCodable_roundTrip_null() throws {
        let original = AnyCodable.null
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(AnyCodable.self, from: data)

        XCTAssertTrue(decoded.isNull)
    }

    func testAnyCodable_roundTrip_array() throws {
        let original = AnyCodable(array: [
            AnyCodable(string: "a"),
            AnyCodable(int: 1),
            AnyCodable(bool: false)
        ])
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(AnyCodable.self, from: data)

        let arr = decoded.arrayValue
        XCTAssertNotNil(arr)
        XCTAssertEqual(arr?.count, 3)
        XCTAssertEqual(arr?[0].stringValue, "a")
        XCTAssertEqual(arr?[1].intValue, 1)
        XCTAssertEqual(arr?[2].boolValue, false)
    }

    func testAnyCodable_roundTrip_dictionary() throws {
        let original = AnyCodable(dictionary: [
            "name": AnyCodable(string: "test"),
            "count": AnyCodable(int: 7),
            "active": AnyCodable(bool: true)
        ])
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(AnyCodable.self, from: data)

        let dict = decoded.dictionaryValue
        XCTAssertNotNil(dict)
        XCTAssertEqual(dict?["name"]?.stringValue, "test")
        XCTAssertEqual(dict?["count"]?.intValue, 7)
        XCTAssertEqual(dict?["active"]?.boolValue, true)
    }

    func testAnyCodable_roundTrip_nestedDictionary() throws {
        let original = AnyCodable(dictionary: [
            "outer": AnyCodable(dictionary: [
                "inner": AnyCodable(string: "deep")
            ])
        ])
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(AnyCodable.self, from: data)

        XCTAssertEqual(decoded["outer"]?["inner"]?.stringValue, "deep")
    }

    func testAnyCodable_equality_sameValues_areEqual() {
        let a = AnyCodable(string: "hello")
        let b = AnyCodable(string: "hello")
        XCTAssertEqual(a, b)

        let c = AnyCodable(int: 42)
        let d = AnyCodable(int: 42)
        XCTAssertEqual(c, d)

        XCTAssertEqual(AnyCodable.null, AnyCodable.null)
    }

    func testAnyCodable_equality_differentValues_areNotEqual() {
        let a = AnyCodable(string: "hello")
        let b = AnyCodable(string: "world")
        XCTAssertNotEqual(a, b)

        let c = AnyCodable(int: 1)
        let d = AnyCodable(string: "1")
        XCTAssertNotEqual(c, d)
    }
}
