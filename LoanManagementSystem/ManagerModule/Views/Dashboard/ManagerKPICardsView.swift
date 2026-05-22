import SwiftUI

// MARK: - Manager KPI Cards View
struct ManagerKPICardsView: View {
    let kpis: [ManagerKPI]

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            Text("Key Performance Indicators")
                .font(.system(.footnote, design: .rounded).bold())
                .foregroundStyle(LMSColors.textSecondary)
                .padding(.horizontal, LMSSpacing.screenHorizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LMSSpacing.md) {
                    ForEach(kpis) { kpi in
                        ManagerKPICard(kpi: kpi)
                    }
                }
                .padding(.horizontal, LMSSpacing.screenHorizontal)
            }
        }
    }
}

// MARK: - Individual KPI Card
private struct ManagerKPICard: View {
    let kpi: ManagerKPI
    @State private var animatedProgress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.sm) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: kpi.icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(kpi.tint)

                Text(kpi.title)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)

                Spacer()
            }

            // Value
            Text(kpi.value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(LMSColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(kpi.tint.opacity(0.15))
                        .frame(height: 4)
                    Capsule()
                        .fill(kpi.tint)
                        .frame(width: geo.size.width * animatedProgress, height: 4)
                }
            }
            .frame(height: 4)

            // Subtitle + Trend
            HStack(spacing: 4) {
                Text(kpi.subtitle)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(kpi.tint)

                Spacer()

                HStack(spacing: 2) {
                    Image(systemName: kpi.trend.icon)
                        .font(.system(size: 8, weight: .bold))
                    Text(kpi.trendValue)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                }
                .foregroundStyle(kpi.trend.color)
            }
        }
        .padding(LMSSpacing.lg)
        .frame(width: 170)
        .background(LMSColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                animatedProgress = kpi.progress
            }
        }
    }
}
