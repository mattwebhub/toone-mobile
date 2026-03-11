import SwiftUI

// MARK: - Chat View

struct ChatView: View {
    @State var viewModel: ChatViewModel?

    var body: some View {
        NavigationStack {
            ZStack {
                OceanDepth.darkBase.ignoresSafeArea()

                if let viewModel {
                    chatContent(viewModel: viewModel)
                } else {
                    placeholderContent
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(OceanDepth.darkBase, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    headerView
                }
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Text(viewModel?.agentDisplayName ?? "Toone")
                .font(AppTypography.Panel.title)
                .foregroundStyle(OceanDepth.textPrimary)

            if let viewModel, viewModel.isProcessing {
                StatusBadge(.processing, label: "Thinking")
            }
        }
    }

    // MARK: - Chat Content

    private func chatContent(viewModel: ChatViewModel) -> some View {
        VStack(spacing: 0) {
            // Connection banner
            if let bannerMessage = viewModel.connectionBannerMessage {
                connectionBanner(message: bannerMessage)
            }

            // Messages list
            messageList(viewModel: viewModel)

            // Pending question
            if let question = viewModel.pendingQuestion {
                questionBanner(question: question, viewModel: viewModel)
            }

            // Input
            ChatInputView(
                text: Binding(
                    get: { viewModel.inputText },
                    set: { viewModel.inputText = $0 }
                ),
                isEnabled: viewModel.canSend,
                isProcessing: viewModel.isProcessing
            ) {
                Task { await viewModel.sendMessage() }
            }
        }
        .task { await viewModel.observeConnectionStatus() }
        .task { await viewModel.observeMessageStream() }
        .task { await viewModel.loadCachedMessages() }
    }

    // MARK: - Connection Banner

    private func connectionBanner(message: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: DesignTokens.IconSize.small))
                .foregroundStyle(OceanDepth.warning)

            Text(message)
                .font(AppTypography.UI.caption)
                .foregroundStyle(OceanDepth.textSecondary)

            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(OceanDepth.warning.opacity(0.1))
    }

    // MARK: - Message List

    private func messageList(viewModel: ChatViewModel) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }

                    if viewModel.isProcessing,
                       viewModel.messages.last?.role != .assistant
                        || viewModel.messages.last?.status != .streaming
                    {
                        TypingIndicator()
                            .id("typing-indicator")
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
            }
            .onChange(of: viewModel.scrollToBottomTrigger) {
                withAnimation(.easeOut(duration: DesignTokens.Animation.defaultDuration)) {
                    if let lastMessage = viewModel.messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    } else if viewModel.isProcessing {
                        proxy.scrollTo("typing-indicator", anchor: .bottom)
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Question Banner

    private func questionBanner(question: AIQuestion, viewModel: ChatViewModel) -> some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Text(question.question)
                .font(AppTypography.UI.body)
                .foregroundStyle(OceanDepth.textPrimary)
                .multilineTextAlignment(.center)

            if question.options.isEmpty {
                // Free-form answer: handled by the input field
                EmptyView()
            } else {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(question.options, id: \.self) { option in
                        Button {
                            Task { await viewModel.answerQuestion(answer: option) }
                        } label: {
                            Text(option)
                                .font(AppTypography.UI.button)
                                .foregroundStyle(OceanDepth.textPrimary)
                                .padding(.horizontal, DesignTokens.Spacing.md)
                                .padding(.vertical, DesignTokens.Spacing.sm)
                                .background(OceanDepth.subtleSurface)
                                .clipShape(
                                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                )
                        }
                    }
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(OceanDepth.elevatedSurface)
    }

    // MARK: - Placeholder

    private var placeholderContent: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: DesignTokens.IconSize.hero))
                .foregroundStyle(OceanDepth.textTertiary)

            Text("No active chat")
                .font(AppTypography.UI.headline)
                .foregroundStyle(OceanDepth.textSecondary)

            Text("Connect to your desktop to start chatting.")
                .font(AppTypography.UI.body)
                .foregroundStyle(OceanDepth.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignTokens.Spacing.xl)
    }
}
