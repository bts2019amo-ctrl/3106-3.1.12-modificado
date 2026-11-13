import SwiftUI

enum AppTheme {
    static let accent = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 1.00, green: 0.64, blue: 0.42, alpha: 1.00)
                : UIColor(red: 0.85, green: 0.42, blue: 0.20, alpha: 1.00)
        }
    )
    static let pageBackground = Color.black
    static let consoleBackground = Color.black
    static let pageInset: CGFloat = 16
    static let rowIconSize: CGFloat = 17
    static let rowIconFrame: CGFloat = 28
    static let fileRowIconSize: CGFloat = 17
    static let fileRowIconFrame: CGFloat = 30
    static let fileRowHeight: CGFloat = 60
    static let appIconSize: CGFloat = 32
    static let emptyIconSize: CGFloat = 30
    static let selectionIconSize: CGFloat = 18
    static let contentCardCornerRadius: CGFloat = 20
    static let contentCardInset: CGFloat = 16
    static let contentCardPadding: CGFloat = 16
}


/// Animated constellation field used behind the app's transparent surfaces.
/// The opacity parameter keeps the calculator version intentionally subtle.
struct ParticleFieldBackground: View {
    var opacity: Double = 1.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { _ in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.008, green: 0.008, blue: 0.008),
                        Color(red: 0.018, green: 0.018, blue: 0.018),
                        .black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                if reduceMotion {
                    Canvas { context, size in
                        Self.drawConstellation(in: &context, size: size, phase: 0)
                    }
                } else {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                        Canvas { context, size in
                            let phase = timeline.date.timeIntervalSinceReferenceDate * 1.35
                            Self.drawConstellation(in: &context, size: size, phase: phase)
                        }
                    }
                }
            }
        }
        .opacity(opacity)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private static func drawConstellation(in context: inout GraphicsContext, size: CGSize, phase: Double) {
        guard size.width > 0, size.height > 0 else { return }
        let count = 25
        let points: [CGPoint] = (0..<count).map { index in
            let seed = Double(index)
            let baseX = (seed * 0.61803398875).truncatingRemainder(dividingBy: 1)
            let baseY = (seed * 0.75487766625 + 0.17).truncatingRemainder(dividingBy: 1)
            let driftX = sin(phase + seed * 1.73) * 0.075
            let driftY = cos(phase * 0.83 + seed * 1.21) * 0.075
            return CGPoint(
                x: CGFloat(min(1, max(0, baseX + driftX))) * size.width,
                y: CGFloat(min(1, max(0, baseY + driftY))) * size.height
            )
        }

        let maxDistance = min(size.width, size.height) * 0.27
        for first in 0..<count {
            for second in (first + 1)..<count {
                let a = points[first]
                let b = points[second]
                let distance = hypot(a.x - b.x, a.y - b.y)
                guard distance < maxDistance else { continue }
                var path = Path()
                path.move(to: a)
                path.addLine(to: b)
                let lineOpacity = Double(0.11 * (1 - distance / maxDistance))
                context.stroke(
                    path,
                    with: .color(Color(red: 0.62, green: 0.64, blue: 0.66).opacity(lineOpacity)),
                    lineWidth: 0.55
                )
            }
        }

        for (index, point) in points.enumerated() {
            let radius: CGFloat = index.isMultiple(of: 5) ? 2.1 : 1.25
            let dot = Path(ellipseIn: CGRect(
                x: point.x - radius,
                y: point.y - radius,
                width: radius * 2,
                height: radius * 2
            ))
            context.fill(
                dot,
                with: .color(Color(red: 0.72, green: 0.74, blue: 0.76).opacity(index.isMultiple(of: 4) ? 0.42 : 0.20))
            )
        }
    }
}

struct AppCardBorder: View {
    var body: some View {
        RoundedRectangle(
            cornerRadius: AppTheme.contentCardCornerRadius,
            style: .continuous
        )
        .strokeBorder(
            Color(uiColor: .separator).opacity(0.22),
            lineWidth: 0.5
        )
        .accessibilityHidden(true)
    }
}

struct AppRowIcon: View {
    let systemName: String
    var tint: Color = AppTheme.accent
    var symbolSize: CGFloat = AppTheme.rowIconSize
    var frameSize: CGFloat = AppTheme.rowIconFrame

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(tint.opacity(0.12))
            Image(systemName: systemName)
                .font(.system(size: symbolSize, weight: .medium))
                .foregroundStyle(tint)
        }
        .frame(width: frameSize, height: frameSize)
        .accessibilityHidden(true)
    }
}

struct AppSearchField: View {
    @Binding var text: String
    let prompt: String
    let clearLabel: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField(prompt, text: $text)
                .font(.body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(clearLabel)
            }
        }
        .padding(.horizontal, 11)
        .frame(minHeight: 36)
        .background(
            Color(uiColor: .secondarySystemFill),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .padding(.horizontal, AppTheme.pageInset)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

struct AppLogo: View {
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let icon = UIImage(named: "AppIcon60x60")
                ?? Bundle.main.path(forResource: "AppIcon60x60@2x", ofType: "png").flatMap(UIImage.init(contentsOfFile:))
                ?? UIImage(named: "AppIcon") {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.accent)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .accessibilityHidden(true)
    }
}
