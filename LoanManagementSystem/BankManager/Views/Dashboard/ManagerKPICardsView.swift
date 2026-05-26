import SwiftUI


struct ManagerKPICardsView: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    let kpis: [ManagerKPI]
    @State private var selectedKPI: ManagerKPI?

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            Text("Key Performance Indicators")
                .font(.system(.footnote, design: .rounded).bold())
                .foregroundStyle(LMSColors.textSecondary)
                .padding(.horizontal, LMSSpacing.screenHorizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LMSSpacing.md) {
                    ForEach(kpis) { kpi in
                        Button(action: {
                            HapticsManager.triggerImpact(style: .light)
                            selectedKPI = kpi
                        }) {
                            ManagerKPICard(kpi: kpi)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, LMSSpacing.screenHorizontal)
            }
        }
        .sheet(item: $selectedKPI) { kpi in
            ManagerApplicantListSheet(
                title: kpi.title,
                systemImage: kpi.icon,
                description: "Details for \(kpi.title)",
                applicants: applicantsFor(kpi: kpi),
                viewModel: viewModel
            )
        }
    }

    private func applicantsFor(kpi: ManagerKPI) -> [ManagerApplicant] {
        if kpi.title.contains("Disbursement") {
            return viewModel.applicants.filter { $0.status == .disbursed }
        } else if kpi.title.contains("Approval") {
            return viewModel.applicants.filter { $0.status == .approved || $0.status == .rejected }
        } else if kpi.title.contains("Default") || kpi.title.contains("Risk") {
            return viewModel.applicants.filter { $0.riskLevel == .high || $0.riskLevel == .critical }
        } else {
            return viewModel.applicants
        }
    }
}


private struct ManagerKPICard: View {
    let kpi: ManagerKPI
    @State private var animatedProgress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: kpi.icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(kpi.tint)

                Text(kpi.title)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)

                Spacer()
            }

                Text(kpi.value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(LMSColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

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
                .padding(.vertical, 2)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                        animatedProgress = kpi.progress
                    }
                }

                HStack {
                    Image(systemName: kpi.trend == .up ? "arrow.up.right" : kpi.trend == .down ? "arrow.down.right" : "minus")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(kpi.trend.color)
                    Text(kpi.trendValue)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(kpi.trend.color)
                    Spacer()
                }

                Text(kpi.subtitle)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(LMSColors.textTertiary)
                    .lineLimit(1)
            }
            .frame(width: 140, alignment: .leading)
            .padding(LMSSpacing.md)
            .background(LMSColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}


#Preview {
    ManagerKPICardsView(viewModel: PreviewSupport.managerViewModel, kpis: PreviewSupport.managerViewModel.kpis)
        .previewManagerEnvironment()
}

