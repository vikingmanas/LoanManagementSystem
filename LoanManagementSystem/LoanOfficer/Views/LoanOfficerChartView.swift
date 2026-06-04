import SwiftUI
import Charts

enum ChartTimeFilter: String, CaseIterable {
    case last7Days = "Last 7 Days"
    case last30Days = "Last 30 Days"
    case thisYear = "This Year"
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let type: String
    let count: Int
}

struct LoanOfficerChartView: View {
    @Bindable var viewModel: LoanOfficerDashboardViewModel
    var onTapAnalytics: () -> Void
    @State private var timeFilter: ChartTimeFilter = .last7Days

    var chartData: [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()

        let startDate: Date
        let component: Calendar.Component

        switch timeFilter {
        case .last7Days:
            startDate = calendar.date(byAdding: .day, value: -6, to: now)!
            component = .day
        case .last30Days:
            startDate = calendar.date(byAdding: .day, value: -29, to: now)!
            component = .day
        case .thisYear:
            startDate = calendar.date(byAdding: .month, value: -11, to: now)!
            component = .month
        }

        var allCounts: [Date: Int] = [:]
        var pendingCounts: [Date: Int] = [:]

        var currentDate = startDate
        while currentDate <= now {
            var dateKey = currentDate
            if component == .day {
                dateKey = calendar.startOfDay(for: currentDate)
            } else {
                let comps = calendar.dateComponents([.year, .month], from: currentDate)
                dateKey = calendar.date(from: comps)!
            }
            allCounts[dateKey] = 0
            pendingCounts[dateKey] = 0
            currentDate = calendar.date(byAdding: component, value: 1, to: currentDate)!
        }

        for app in viewModel.applications {
            guard app.submittedDate >= startDate else { continue }

            var dateKey = app.submittedDate
            if component == .day {
                dateKey = calendar.startOfDay(for: dateKey)
            } else {
                let comps = calendar.dateComponents([.year, .month], from: dateKey)
                dateKey = calendar.date(from: comps)!
            }

            allCounts[dateKey, default: 0] += 1
            if app.status == .pending || app.status == .applied {
                pendingCounts[dateKey, default: 0] += 1
            }
        }

        var result: [ChartDataPoint] = []
        let sortedDates = allCounts.keys.sorted()
        for date in sortedDates {
            result.append(ChartDataPoint(date: date, type: "All", count: allCounts[date] ?? 0))
            result.append(ChartDataPoint(date: date, type: "Pending", count: pendingCounts[date] ?? 0))
        }

        return result
    }

    var body: some View {
        let currentUnit: Calendar.Component = timeFilter == .thisYear ? .month : .day
        let isYear = timeFilter == .thisYear

        VStack(alignment: .leading, spacing: 18) {

            Button(action: {
                HapticsManager.triggerImpact(style: .light)
                onTapAnalytics()
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Applications Trend")
                            .font(.system(.title3, design: .rounded).bold())
                            .foregroundStyle(LMSColors.textPrimary)
                        Text("Tap for detailed analytics")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(LMSColors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color(hex: "F3F4F6"), AppTheme.actionBlue)
                }
            }
            .buttonStyle(PlainButtonStyle())


            HStack {
                Spacer()
                Picker("Time Filter", selection: $timeFilter) {
                    ForEach(ChartTimeFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.bottom, 8)


            if chartData.isEmpty {
                ContentUnavailableView("No Data", systemImage: "chart.bar.xaxis")
            } else {
                Chart {
                    ForEach(chartData) { point in
                        BarMark(
                            x: .value("Date", point.date, unit: currentUnit),
                            y: .value("Count", point.count)
                        )
                        .foregroundStyle(by: .value("Type", point.type))
                        .position(by: .value("Type", point.type))
                        .cornerRadius(6)
                    }
                }
                .chartForegroundStyleScale([
                    "All": AppTheme.actionBlue,
                    "Pending": AppTheme.warningAmber
                ])
                .chartXAxis {
                    AxisMarks(values: .stride(by: currentUnit)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(isYear ? date.formatted(.dateTime.month()) : date.formatted(.dateTime.day().month()))
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundStyle(LMSColors.textSecondary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [4]))
                            .foregroundStyle(Color.gray.opacity(0.2))
                        AxisValueLabel {
                            if let count = value.as(Int.self) {
                                Text("\(count)")
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundStyle(LMSColors.textSecondary)
                            }
                        }
                    }
                }
                .frame(height: 220)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }
}


