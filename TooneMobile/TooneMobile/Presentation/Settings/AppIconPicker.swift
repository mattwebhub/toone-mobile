import SwiftUI

// MARK: - App Icon Option

struct AppIconOption: Identifiable {
    let id: String  // matches the CFBundleAlternateIcons key, nil string for default
    let name: String
    let previewImageName: String  // asset catalog image for preview
    let isDefault: Bool

    static let allIcons: [AppIconOption] = [
        AppIconOption(id: "default", name: "Classic", previewImageName: "AppIconPreview-Default", isDefault: true),
        AppIconOption(id: "OceanDepth", name: "Ocean Depth", previewImageName: "AppIconPreview-OceanDepth", isDefault: false),
        AppIconOption(id: "Midnight", name: "Midnight", previewImageName: "AppIconPreview-Midnight", isDefault: false),
        AppIconOption(id: "Aurora", name: "Aurora", previewImageName: "AppIconPreview-Aurora", isDefault: false),
    ]
}

// MARK: - App Icon Picker View

struct AppIconPickerView: View {
    @State private var currentIcon: String? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                OceanDepth.darkBase.ignoresSafeArea()

                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: DesignTokens.Spacing.md)
                    ], spacing: DesignTokens.Spacing.md) {
                        ForEach(AppIconOption.allIcons) { icon in
                            iconCell(icon)
                        }
                    }
                    .padding(DesignTokens.Spacing.md)
                }
            }
            .navigationTitle("App Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(OceanDepth.darkBase, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            currentIcon = UIApplication.shared.alternateIconName
        }
    }

    // MARK: - Icon Cell

    private func iconCell(_ icon: AppIconOption) -> some View {
        let isSelected = icon.isDefault ? (currentIcon == nil) : (currentIcon == icon.id)

        return Button {
            setIcon(icon)
        } label: {
            VStack(spacing: DesignTokens.Spacing.sm) {
                // Icon preview - use a placeholder rounded rect for now
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                    .fill(OceanDepth.elevatedSurface)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "app.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(isSelected ? Color.accentColor : OceanDepth.textSecondary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )

                Text(icon.name)
                    .font(AppTypography.UI.caption)
                    .foregroundStyle(isSelected ? OceanDepth.textPrimary : OceanDepth.textSecondary)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: DesignTokens.IconSize.small))
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Set Icon

    private func setIcon(_ icon: AppIconOption) {
        let iconName: String? = icon.isDefault ? nil : icon.id

        guard UIApplication.shared.supportsAlternateIcons else { return }

        UIApplication.shared.setAlternateIconName(iconName) { error in
            if error == nil {
                currentIcon = iconName
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AppIconPickerView()
}
