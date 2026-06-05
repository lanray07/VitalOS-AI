import Charts
import SwiftUI

extension Color {
    static let obsidian = Color(red: 0.015, green: 0.018, blue: 0.026)
    static let panel = Color(red: 0.05, green: 0.065, blue: 0.085)
    static let electricBlue = Color(red: 0.1, green: 0.55, blue: 1.0)
    static let vitalEmerald = Color(red: 0.0, green: 0.9, blue: 0.58)
    static let softText = Color.white.opacity(0.74)
}

struct ObsidianBackground: View {
    var body: some View {
        LinearGradient(colors: [.obsidian, Color(red: 0.02, green: 0.028, blue: 0.04), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
            .overlay {
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        let time = timeline.date.timeIntervalSince1970
                        for index in 0..<9 {
                            let progress = (sin(time * 0.35 + Double(index)) + 1) / 2
                            let x = size.width * CGFloat(Double(index) / 8)
                            let y = size.height * CGFloat(0.18 + progress * 0.64)
                            var path = Path()
                            path.addEllipse(in: CGRect(x: x - 1, y: y - 1, width: 2, height: 2))
                            context.fill(path, with: .color(index.isMultiple(of: 2) ? .electricBlue.opacity(0.22) : .vitalEmerald.opacity(0.18)))
                        }
                    }
                    .blur(radius: 18)
                }
            }
    }
}

struct GlassPanel<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            }
            .shadow(color: .electricBlue.opacity(0.16), radius: 18, x: 0, y: 10)
    }
}

struct VitalScoreRing: View {
    var score: Int
    var title: String = "Vital Score"
    var tint: Color = .electricBlue

    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.08), lineWidth: 18)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(AngularGradient(colors: [tint, .vitalEmerald, tint], center: .center), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: tint.opacity(0.55), radius: 14)
            VStack(spacing: 4) {
                Text("\(score)")
                    .font(.system(size: 52, weight: .semibold, design: .rounded))
                Text(title.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.softText)
            }
        }
        .frame(width: 220, height: 220)
        .accessibilityLabel("\(title) \(score)")
    }
}

struct MetricCard: View {
    var metric: WellnessMetric

    var body: some View {
        GlassPanel(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(metric.title)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.softText)
                    Spacer()
                    Circle()
                        .fill(metric.tintName == "emerald" ? .vitalEmerald : .electricBlue)
                        .frame(width: 8, height: 8)
                }
                Text("\(metric.value)")
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                ProgressView(value: Double(metric.value), total: 100)
                    .tint(metric.tintName == "emerald" ? .vitalEmerald : .electricBlue)
            }
        }
    }
}

struct RecoveryCard: View {
    var score: Int
    var body: some View {
        MetricCard(metric: .init(title: "Recovery", value: score, tintName: "emerald"))
    }
}

struct SleepCard: View {
    var score: Int
    var body: some View {
        MetricCard(metric: .init(title: "Sleep", value: score, tintName: "blue"))
    }
}

struct ProtocolCard: View {
    var item: ProtocolRecommendation

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(item.category.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.vitalEmerald)
                    Spacer()
                    Image(systemName: "sparkles")
                        .foregroundStyle(.electricBlue)
                }
                Text(item.title)
                    .font(.headline)
                Text(item.detail)
                    .font(.subheadline)
                    .foregroundStyle(.softText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct VoiceWaveformView: View {
    var levels: [CGFloat]
    var active: Bool

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(levels.enumerated()), id: \.offset) { _, level in
                Capsule()
                    .fill(LinearGradient(colors: [.electricBlue, .vitalEmerald], startPoint: .top, endPoint: .bottom))
                    .frame(width: 5, height: max(8, 72 * level))
                    .opacity(active ? 1 : 0.45)
                    .animation(.spring(response: 0.28, dampingFraction: 0.72), value: level)
            }
        }
        .frame(height: 92)
        .accessibilityLabel(active ? "Recording waveform active" : "Recording waveform idle")
    }
}

struct AnalyticsChartCard: View {
    var title: String
    var values: [Int]
    var tint: Color = .electricBlue

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline)
                Chart(Array(values.enumerated()), id: \.offset) { index, value in
                    LineMark(x: .value("Day", index + 1), y: .value("Score", value))
                        .foregroundStyle(tint)
                    AreaMark(x: .value("Day", index + 1), y: .value("Score", value))
                        .foregroundStyle(tint.opacity(0.18))
                }
                .chartYScale(domain: 0...100)
                .frame(height: 150)
            }
        }
    }
}

struct ProjectionCard: View {
    var scenario: ProjectionScenario

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text(scenario.title)
                    .font(.headline)
                HStack(alignment: .lastTextBaseline) {
                    Text("\(scenario.currentValue)")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(.softText)
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.electricBlue)
                    Text("\(scenario.projectedValue)")
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(.vitalEmerald)
                }
                Text(scenario.caption)
                    .font(.caption)
                    .foregroundStyle(.softText)
            }
        }
    }
}

struct ShareCardPreview: View {
    var title: String
    var value: String
    var caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("VitalOS AI")
                .font(.caption.weight(.bold))
                .foregroundStyle(.electricBlue)
            Text(title)
                .font(.title3.weight(.semibold))
            Text(value)
                .font(.system(size: 54, weight: .bold, design: .rounded))
                .foregroundStyle(.vitalEmerald)
            Text(caption)
                .font(.subheadline)
                .foregroundStyle(.softText)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.electricBlue.opacity(0.35)))
    }
}

struct UpgradeBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bolt.badge.automatic")
                .foregroundStyle(.vitalEmerald)
            VStack(alignment: .leading, spacing: 2) {
                Text("Adaptive protocols are a premium capability")
                    .font(.subheadline.weight(.semibold))
                Text("Unlock deeper AI personalization and projections.")
                    .font(.caption)
                    .foregroundStyle(.softText)
            }
            Spacer()
        }
        .padding(14)
        .background(.electricBlue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct PrimaryButton: View {
    var title: String
    var systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(.electricBlue)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
