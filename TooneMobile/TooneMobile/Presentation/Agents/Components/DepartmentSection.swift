import SwiftUI

// MARK: - Department Section

struct DepartmentSection: View {
    let department: Department
    let selectedAgent: Agent?
    let onSelectAgent: (Agent) -> Void

    @State private var isExpanded: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Section header
            sectionHeader

            // Agent list
            if isExpanded {
                agentList
            }
        }
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        Button {
            withAnimation(.spring(
                response: DesignTokens.Animation.springResponse,
                dampingFraction: DesignTokens.Animation.springDamping
            )) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Text(department.name.uppercased())
                    .font(AppTypography.UI.badge)
                    .foregroundStyle(OceanDepth.textTertiary)

                Text("\(department.agents.count)")
                    .font(AppTypography.UI.badge)
                    .foregroundStyle(OceanDepth.textTertiary)
                    .padding(.horizontal, DesignTokens.Spacing.sm)
                    .padding(.vertical, 2)
                    .background(OceanDepth.subtleSurface)
                    .clipShape(Capsule())

                Spacer()

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: AppTypography.Size.xxs))
                    .foregroundStyle(OceanDepth.textTertiary)
            }
            .padding(.horizontal, DesignTokens.Spacing.xs)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Agent List

    private var agentList: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(department.agents) { agent in
                AgentCard(
                    agent: agent,
                    isSelected: selectedAgent?.id == agent.id
                ) {
                    onSelectAgent(agent)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        OceanDepth.darkBase.ignoresSafeArea()

        ScrollView {
            DepartmentSection(
                department: Department(
                    id: "eng",
                    name: "Engineering",
                    agents: [
                        Agent(
                            id: "1",
                            name: "Code Assistant",
                            description: "Helps with coding tasks.",
                            departmentId: "eng",
                            capabilities: ["Swift", "Python"],
                            routineNames: [],
                            greeting: nil,
                            isSystem: false
                        ),
                        Agent(
                            id: "2",
                            name: "DevOps Helper",
                            description: "Infrastructure and deployment help.",
                            departmentId: "eng",
                            capabilities: ["Docker", "CI/CD"],
                            routineNames: [],
                            greeting: nil,
                            isSystem: false
                        ),
                    ]
                ),
                selectedAgent: nil,
                onSelectAgent: { _ in }
            )
            .padding(DesignTokens.Spacing.md)
        }
    }
}
