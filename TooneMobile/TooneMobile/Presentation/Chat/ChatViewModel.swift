import Foundation

// MARK: - AI Question

struct AIQuestion: Identifiable, Sendable {
    let id: String
    let question: String
    let options: [String]
}

// MARK: - Chat View Model

@Observable @MainActor
final class ChatViewModel {
    var messages: [Message] = []
    var inputText: String = ""
    var isProcessing: Bool = false
    var currentAgent: Agent?
    var connectionStatus: ConnectionStatus = .disconnected
    var connectionRole: ConnectionRole = .viewer
    var pendingQuestion: AIQuestion?
    var scrollToBottomTrigger: UUID = UUID()

    private let messageRepository: MessageRepository
    private let connectionRepository: ConnectionRepository

    // MARK: - Init

    init(messageRepository: MessageRepository, connectionRepository: ConnectionRepository) {
        self.messageRepository = messageRepository
        self.connectionRepository = connectionRepository
    }

    // MARK: - Computed Properties

    var isConnected: Bool {
        if case .connected = connectionStatus { return true }
        return false
    }

    var canSendMessages: Bool {
        connectionRole.canSendMessages
    }

    var canSend: Bool {
        isConnected && canSendMessages && !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isProcessing
    }

    var agentDisplayName: String {
        currentAgent?.name ?? "Toone"
    }

    var connectionBannerMessage: String? {
        switch connectionStatus {
        case .disconnected:
            return "Not connected to desktop"
        case .reconnecting(let attempt, let maxAttempts):
            return "Reconnecting (\(attempt)/\(maxAttempts))..."
        case .failed(let error):
            switch error {
            case .unreachable: return "Desktop unreachable"
            case .timeout: return "Connection timed out"
            case .desktopDisconnected: return "Desktop disconnected"
            default: return "Connection error"
            }
        case .connecting, .authenticating, .syncing, .discovering:
            return "Connecting..."
        case .connected:
            return nil
        }
    }

    // MARK: - Actions

    func sendMessage() async {
        guard connectionRole.canSendMessages else { return }
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty, isConnected else { return }

        let agentId = currentAgent?.id ?? ""
        let sessionId = currentAgent?.sessionId

        // Create local user message immediately for responsiveness
        let userMessage = Message(
            id: UUID().uuidString,
            role: .user,
            timestamp: Date(),
            content: [.text(TextContent(text: trimmedText))],
            status: .sending,
            sessionId: sessionId
        )

        messages.append(userMessage)
        inputText = ""
        isProcessing = true
        scrollToBottomTrigger = UUID()

        do {
            let response = try await messageRepository.sendMessage(
                content: trimmedText,
                agentId: agentId,
                sessionId: sessionId
            )

            // Replace the sending message with the confirmed one
            if let index = messages.firstIndex(where: { $0.id == userMessage.id }) {
                messages[index] = Message(
                    id: userMessage.id,
                    role: .user,
                    timestamp: userMessage.timestamp,
                    content: userMessage.content,
                    status: .completed,
                    sessionId: sessionId
                )
            }

            // The response message from the server
            messages.append(response)
            scrollToBottomTrigger = UUID()
        } catch {
            // Mark the user message as failed
            if let index = messages.firstIndex(where: { $0.id == userMessage.id }) {
                messages[index] = Message(
                    id: userMessage.id,
                    role: .user,
                    timestamp: userMessage.timestamp,
                    content: userMessage.content,
                    status: .failed,
                    sessionId: sessionId
                )
            }
        }

        isProcessing = false
    }

    func answerQuestion(answer: String) async {
        guard let question = pendingQuestion else { return }

        do {
            try await messageRepository.answerQuestion(
                questionId: question.id,
                answer: answer
            )
            pendingQuestion = nil
        } catch {
            // Question answering failed; keep the question pending
        }
    }

    func loadCachedMessages() async {
        guard let sessionId = currentAgent?.sessionId else { return }
        let cached = await messageRepository.cachedMessages(sessionId: sessionId)
        messages = cached
    }

    func observeConnectionStatus() async {
        for await status in connectionRepository.statusStream {
            connectionStatus = status
            if case .connected(let info) = status {
                connectionRole = info.role
            }
        }
    }

    func observeMessageStream() async {
        guard let sessionId = currentAgent?.sessionId else { return }

        for await message in messageRepository.messageStream(sessionId: sessionId) {
            // Update existing streaming message or add new one
            if let index = messages.firstIndex(where: { $0.id == message.id }) {
                messages[index] = message
            } else {
                messages.append(message)
            }
            scrollToBottomTrigger = UUID()

            if message.status == .streaming {
                isProcessing = true
            } else if message.status == .completed {
                isProcessing = false
            }
        }
    }
}
