import SwiftUI

enum AppTheme {
    // Surfaces (Fixed Zinc Dark Palette)
    static let windowBg        = Color(red: 18/255, green: 18/255, blue: 20/255)   // #121214
    static let sidebarBg       = Color(red: 24/255, green: 24/255, blue: 27/255)   // #18181b
    static let panelBg         = Color(red: 22/255, green: 22/255, blue: 24/255)   // #161618
    static let cardWaitingBg   = Color(red: 31/255, green: 31/255, blue: 35/255)   // #1f1f23
    static let cardSelectedBg  = Color(red: 46/255, green: 42/255, blue: 82/255)   // #2e2a52
    static let cardRunningBg   = Color(red: 39/255, green: 35/255, blue: 61/255)   // #27233d
    static let cardDoneBg      = Color(red: 23/255, green: 36/255, blue: 29/255)   // #17241d
    static let cardErrorBg     = Color(red: 39/255, green: 26/255, blue: 26/255)   // #271a1a
    static let cardCancelledBg = Color(red: 36/255, green: 31/255, blue: 24/255)   // #241f18
    static let dropZoneBg      = Color(red: 24/255, green: 24/255, blue: 28/255)   // #18181c

    // Borders & Dividers
    static let borderSubtle    = Color(red: 39/255, green: 39/255, blue: 42/255)   // #27272a
    static let borderCard      = Color(red: 50/255, green: 50/255, blue: 56/255)   // #323238
    static let borderDashed    = Color(red: 63/255, green: 63/255, blue: 70/255)   // #3f3f46

    // Text Hierarchy
    static let textTitle       = Color.white                                        // #ffffff
    static let textPrimary     = Color(red: 228/255, green: 228/255, blue: 231/255) // #e4e4e7
    static let textSecondary   = Color(red: 161/255, green: 161/255, blue: 170/255) // #a1a1aa
    static let textMuted       = Color(red: 113/255, green: 113/255, blue: 122/255) // #71717a

    // Semantic Accents
    static let indigo          = Color(red: 129/255, green: 140/255, blue: 248/255) // #818cf8
    static let indigoHover     = Color(red: 109/255, green: 120/255, blue: 245/255) // #6d78f5
    static let emerald         = Color(red: 16/255, green: 185/255, blue: 129/255)  // #10b981
    static let emeraldHover    = Color(red: 5/255, green: 150/255, blue: 105/255)   // #059669
    static let amber           = Color(red: 245/255, green: 158/255, blue: 11/255)  // #f59e0b
    static let amberDark       = Color(red: 217/255, green: 119/255, blue: 6/255)   // #d97706
    static let amberDarkHover  = Color(red: 180/255, green: 83/255, blue: 9/255)    // #b45309
    static let danger          = Color(red: 239/255, green: 68/255, blue: 68/255)   // #ef4444
    static let dangerHover     = Color(red: 220/255, green: 38/255, blue: 38/255)   // #dc2626

    static let buttonSecondaryBg    = Color(red: 39/255, green: 39/255, blue: 42/255) // #27272a
    static let buttonSecondaryHover = Color(red: 42/255, green: 42/255, blue: 48/255) // #2a2a30
    static let buttonToggleBg       = Color(red: 34/255, green: 34/255, blue: 38/255) // #222226
    static let buttonToggleBorder   = Color(red: 56/255, green: 56/255, blue: 64/255) // #383840

    // Unified Geometry ("Apple Squircle Concentrico")
    static let cardRadius: CGFloat         = 12
    static let controlRadius: CGFloat      = 10
    static let innerControlRadius: CGFloat = 7
}

@Observable
private final class HoverState {
    var isHovered = false
}

struct SolidRoundedButtonStyle: ButtonStyle {
    let background: Color
    let hoverBackground: Color
    var foreground: Color = AppTheme.textTitle
    var borderColor: Color? = nil
    var hoverBorderColor: Color? = nil
    var cornerRadius: CGFloat = AppTheme.controlRadius
    var minHeight: CGFloat = 34
    var horizontalPadding: CGFloat = 14

    @Environment(\.isEnabled) private var isEnabled
    private let hoverState = HoverState()

    func makeBody(configuration: Configuration) -> some View {
        let isHovered = hoverState.isHovered
        let bg: Color = {
            if !isEnabled { return AppTheme.buttonSecondaryBg }
            if configuration.isPressed { return hoverBackground.opacity(0.9) }
            return isHovered ? hoverBackground : background
        }()
        let fg: Color = isEnabled ? foreground : AppTheme.textMuted
        let stroke: Color? = {
            if !isEnabled { return AppTheme.borderSubtle }
            if isHovered, let hoverBorderColor { return hoverBorderColor }
            return borderColor
        }()

        configuration.label
            .font(.callout.weight(.semibold))
            .foregroundStyle(fg)
            .padding(.horizontal, horizontalPadding)
            .frame(minHeight: minHeight)
            .background(bg)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(stroke ?? Color.clear, lineWidth: stroke == nil ? 0 : 1.2)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .scaleEffect(configuration.isPressed && isEnabled ? 0.985 : 1.0)
            .animation(.easeOut(duration: 0.12), value: isHovered)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
            .onHover { hovering in
                hoverState.isHovered = hovering
            }
    }
}

struct AppleSwitchToggleStyle: ToggleStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let isOn = configuration.isOn
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                configuration.label
                Spacer(minLength: 8)
                ZStack(alignment: isOn ? .trailing : .leading) {
                    RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                        .fill(isOn ? AppTheme.indigo : AppTheme.buttonToggleBg)
                        .frame(width: 36, height: 20)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                                .stroke(isOn ? AppTheme.indigo : AppTheme.buttonToggleBorder, lineWidth: 1)
                        )

                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .shadow(color: Color.black.opacity(0.28), radius: 1.5, x: 0, y: 1)
                        .padding(.horizontal, 2)
                }
                .opacity(isEnabled ? 1.0 : 0.45)
                .animation(.spring(response: 0.22, dampingFraction: 1.0), value: isOn)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct AppleSegmentedSwitch: View {
    let leftTitle: String
    let rightTitle: String
    let isLeftSelected: Bool
    let onSelectLeft: () -> Void
    let onSelectRight: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        GeometryReader { geo in
            let halfWidth = max(40, (geo.size.width - 6) / 2)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                    .fill(AppTheme.panelBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                            .stroke(AppTheme.borderCard, lineWidth: 1)
                    )

                RoundedRectangle(cornerRadius: AppTheme.innerControlRadius, style: .continuous)
                    .fill(AppTheme.indigo)
                    .frame(width: halfWidth, height: 26)
                    .offset(x: isLeftSelected ? 3 : halfWidth + 3)
                    .animation(.spring(response: 0.24, dampingFraction: 1.0), value: isLeftSelected)

                HStack(spacing: 0) {
                    Button(action: onSelectLeft) {
                        Text(leftTitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isLeftSelected ? AppTheme.textTitle : AppTheme.textSecondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Button(action: onSelectRight) {
                        Text(rightTitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(!isLeftSelected ? AppTheme.textTitle : AppTheme.textSecondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(height: 32)
        .opacity(isEnabled ? 1.0 : 0.5)
    }
}

struct FlatProgressBar: View {
    let value: Double
    var total: Double = 100.0
    var tint: Color = AppTheme.indigo
    var trackColor: Color = Color(red: 36/255, green: 36/255, blue: 40/255) // #242428
    var height: CGFloat = 8

    var body: some View {
        let ratio = total > 0 ? min(1.0, max(0.0, value / total)) : 0.0
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(trackColor)

                if ratio > 0 {
                    Capsule(style: .continuous)
                        .fill(tint)
                        .frame(width: geo.size.width * ratio)
                }
            }
        }
        .frame(height: height)
        .clipShape(Capsule(style: .continuous))
        .animation(.easeOut(duration: 0.15), value: ratio)
    }
}
