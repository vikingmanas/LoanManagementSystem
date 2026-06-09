import SwiftUI

struct ApplicationAssignmentSheet: View {
    let applicant: ManagerApplicant
    let officers: [ManagerOfficer]
    let onAssign: (UUID) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var searchQuery = ""
    @State private var selectedFilter: OfficerAvailabilityFilter = .all
    @State private var pendingOfficerId: UUID? = nil
    @State private var showSuccess = false
    @State private var successOfficerName = ""

    enum OfficerAvailabilityFilter: String, CaseIterable {
        case all       = "All"
        case available = "Available"
        case busy      = "Near Limit"

        var systemImage: String {
            switch self {
            case .all:       return "person.3.fill"
            case .available: return "checkmark.circle.fill"
            case .busy:      return "exclamationmark.circle.fill"
            }
        }

        var tint: Color {
            switch self {
            case .all:       return LMSColors.brandNavy
            case .available: return LMSColors.emerald
            case .busy:      return LMSColors.coral
            }
        }
    }

    private var filteredOfficers: [ManagerOfficer] {
        var result = officers

        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(q) ||
                $0.role.localizedCaseInsensitiveContains(q)
            }
        }

        switch selectedFilter {
        case .all: break
        case .available: result = result.filter { $0.capacityPercentage < 0.75 }
        case .busy:      result = result.filter { $0.capacityPercentage >= 0.75 }
        }

        return result.sorted {
            if $0.id == applicant.assignedOfficerId { return true  }
            if $1.id == applicant.assignedOfficerId { return false }
            return $0.capacityPercentage < $1.capacityPercentage
        }
    }

    private var availableCount: Int { officers.filter { $0.capacityPercentage < 0.75 }.count }
    private var busyCount: Int { officers.count - availableCount }

    var body: some View {
        NavigationStack {
            ZStack {
                LMSColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    applicationHeader
                    statsStrip
                    Divider()
                    filterAndSearch
                    Divider()
                    officerList
                }
            }
            .navigationTitle("Assign Application")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)
                }
            }
        }
        .overlay(alignment: .center) {
            if showSuccess {
                successOverlay
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.82).combined(with: .opacity),
                        removal:   .opacity
                    ))
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.78), value: showSuccess)
    }

    private var applicationHeader: some View {
        HStack(spacing: LMSSpacing.md) {

            ZStack {
                RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous)
                    .fill(applicant.loanType.themeColor.opacity(0.14))
                    .frame(width: 52, height: 52)
                Image(systemName: applicant.loanType.symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(applicant.loanType.themeColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(applicant.borrowerName)
                    .font(.system(.callout, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)

                HStack(spacing: LMSSpacing.xs) {
                    Text(applicant.applicationId)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(LMSColors.textTertiary)
                    Text("·").foregroundStyle(LMSColors.textTertiary)

                    HStack(spacing: 3) {
                        Image(systemName: applicant.loanType.symbol)
                            .font(.system(size: 7, weight: .bold))
                        Text(applicant.loanType.rawValue)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(applicant.loanType.themeColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(applicant.loanType.themeColor.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(CurrencyFormatter.shared.format(applicant.requestedAmount))
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)
                HStack(spacing: 3) {
                    Circle()
                        .fill(applicant.riskLevel.themeColor)
                        .frame(width: 5, height: 5)
                    Text(applicant.riskLevel.rawValue)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(applicant.riskLevel.themeColor)
                    Text("Risk")
                        .font(.system(size: 9, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, LMSSpacing.screenHorizontal)
        .padding(.vertical, LMSSpacing.lg)
        .background(LMSColors.surfaceElevated)
    }

    private var statsStrip: some View {
        HStack(spacing: 0) {
            AssignmentStatPill(icon: "person.3.fill",
                               value: "\(officers.count)",
                               label: "Total Officers",
                               tint: LMSColors.brandNavy)
            Divider().frame(height: 28)
            AssignmentStatPill(icon: "checkmark.circle.fill",
                               value: "\(availableCount)",
                               label: "Available",
                               tint: LMSColors.emerald)
            Divider().frame(height: 28)
            AssignmentStatPill(icon: "exclamationmark.circle.fill",
                               value: "\(busyCount)",
                               label: "Near Limit",
                               tint: LMSColors.coral)
        }
        .padding(.vertical, LMSSpacing.sm)
        .background(LMSColors.surface)
    }

    private var filterAndSearch: some View {
        VStack(spacing: LMSSpacing.sm) {

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(LMSColors.textSecondary)
                    .font(.system(size: 14))
                TextField("Search by name or role…", text: $searchQuery)
                    .font(.system(.body, design: .rounded))
                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(LMSColors.textTertiary)
                    }
                }
            }
            .padding(.horizontal, LMSSpacing.lg)
            .padding(.vertical, 10)
            .background(LMSColors.background)
            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous)
                    .stroke(LMSColors.separatorLight, lineWidth: 0.5)
            )

            HStack(spacing: LMSSpacing.sm) {
                ForEach(OfficerAvailabilityFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        HapticsManager.triggerImpact(style: .light)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedFilter = filter
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: filter.systemImage)
                                .font(.system(size: 9, weight: .bold))
                            Text(filter.rawValue)
                                .font(.system(.caption, design: .rounded).bold())
                        }
                        .foregroundStyle(selectedFilter == filter ? .white : LMSColors.textSecondary)
                        .padding(.horizontal, LMSSpacing.md)
                        .padding(.vertical, LMSSpacing.sm)
                        .background(selectedFilter == filter ? filter.tint : LMSColors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(selectedFilter == filter ? Color.clear : LMSColors.separatorLight,
                                        lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(LMSPressableStyle())
                }

                Spacer()

                Text("\(filteredOfficers.count) shown")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(LMSColors.textTertiary)
            }
        }
        .padding(.horizontal, LMSSpacing.screenHorizontal)
        .padding(.vertical, LMSSpacing.md)
        .background(LMSColors.surfaceElevated)
    }

    private var officerList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: LMSSpacing.sm) {
                if filteredOfficers.isEmpty {
                    ContentUnavailableView(
                        "No Officers Found",
                        systemImage: "person.slash.fill",
                        description: Text("Try adjusting your search or filter.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {

                    let currentOfficer = filteredOfficers.first { $0.id == applicant.assignedOfficerId }
                    let otherOfficers  = filteredOfficers.filter { $0.id != applicant.assignedOfficerId }

                    if let current = currentOfficer {
                        AssignmentSectionLabel(title: "CURRENTLY ASSIGNED")
                        OfficerAssignmentCard(
                            officer: current,
                            applicantLoanType: applicant.loanType,
                            isCurrentlyAssigned: true,
                            isProcessing: pendingOfficerId == current.id,
                            onAssign: { performAssign(officer: current) }
                        )
                    }

                    if !otherOfficers.isEmpty {
                        AssignmentSectionLabel(
                            title: currentOfficer != nil ? "REASSIGN TO" : "SELECT OFFICER"
                        )
                        ForEach(otherOfficers) { officer in
                            OfficerAssignmentCard(
                                officer: officer,
                                applicantLoanType: applicant.loanType,
                                isCurrentlyAssigned: false,
                                isProcessing: pendingOfficerId == officer.id,
                                onAssign: { performAssign(officer: officer) }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)
            .padding(.top, LMSSpacing.md)
            .padding(.bottom, LMSSpacing.xxxl)
        }
        .background(LMSColors.background)
    }

    private var successOverlay: some View {
        VStack(spacing: LMSSpacing.lg) {
            ZStack {
                Circle()
                    .fill(LMSColors.emerald.opacity(0.18))
                    .frame(width: 84, height: 84)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(LMSColors.emerald)
            }
            VStack(spacing: LMSSpacing.xs) {
                Text("Assigned!")
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundStyle(.white)
                Text(successOfficerName)
                    .font(.system(.callout, design: .rounded))
                    .foregroundStyle(.white.opacity(0.80))
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, LMSSpacing.xl)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.xl, style: .continuous))
        .shadow(color: .black.opacity(0.22), radius: 24, x: 0, y: 12)
    }

    private func performAssign(officer: ManagerOfficer) {
        guard pendingOfficerId == nil else { return }
        HapticsManager.triggerImpact(style: .heavy)
        pendingOfficerId    = officer.id
        successOfficerName  = officer.name

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.75)) {
                showSuccess = true
            }
            HapticsManager.triggerNotification(type: .success)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) {
            onAssign(officer.id)
            withAnimation { showSuccess = false; pendingOfficerId = nil }
            dismiss()
        }
    }
}

struct OfficerAssignmentCard: View {
    let officer: ManagerOfficer
    let applicantLoanType: ManagerLoanType
    let isCurrentlyAssigned: Bool
    let isProcessing: Bool
    let onAssign: () -> Void

    private var avatarColors: [Color] {
        let palette: [[Color]] = [
            [LMSColors.brandNavy,  LMSColors.actionBlue],
            [LMSColors.teal,       LMSColors.emerald],
            [Color.purple,         LMSColors.actionBlue],
            [LMSColors.actionBlue, LMSColors.teal],
            [LMSColors.emerald,    LMSColors.teal],
        ]
        return palette[abs(officer.name.hashValue) % palette.count]
    }

    var body: some View {
        HStack(spacing: 0) {

            Rectangle()
                .fill(isCurrentlyAssigned ? LMSColors.emerald : officer.capacityColor)
                .frame(width: 3)

            VStack(spacing: 0) {

                HStack(alignment: .top, spacing: LMSSpacing.md) {

                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: avatarColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 52, height: 52)
                        Text(officer.initials)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .overlay(
                        Circle()
                            .stroke(isCurrentlyAssigned ? LMSColors.emerald : Color.clear,
                                    lineWidth: 2.5)
                            .padding(-3)
                    )

                    VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                        HStack(spacing: LMSSpacing.sm) {
                            Text(officer.name)
                                .font(.system(.callout, design: .rounded).bold())
                                .foregroundStyle(LMSColors.textPrimary)
                            if isCurrentlyAssigned {
                                HStack(spacing: 3) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 9, weight: .bold))
                                    Text("Current")
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(LMSColors.emerald)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(LMSColors.emerald.opacity(0.10))
                                .clipShape(Capsule())
                            }
                        }

                        Text(officer.role)
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(LMSColors.textSecondary)

                        HStack(spacing: LMSSpacing.xs) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(LMSColors.separatorLight)
                                        .frame(height: 5)
                                    Capsule()
                                        .fill(officer.capacityColor)
                                        .frame(
                                            width: geo.size.width * min(1.0, officer.capacityPercentage),
                                            height: 5
                                        )
                                }
                            }
                            .frame(height: 5)

                            Text("\(officer.activeCases)/\(officer.maxCapacity)")
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundStyle(officer.capacityColor)
                                .monospacedDigit()
                                .frame(minWidth: 30, alignment: .trailing)
                        }
                    }

                    Spacer(minLength: LMSSpacing.sm)

                    VStack(spacing: LMSSpacing.sm) {

                        if officer.loansProcessedYTD > 0 {
                            ZStack {
                                Circle()
                                    .stroke(LMSColors.emerald.opacity(0.14), lineWidth: 3.5)
                                    .frame(width: 34, height: 34)
                                Circle()
                                    .trim(from: 0, to: min(1, officer.approvalRate / 100))
                                    .stroke(
                                        LMSColors.emerald,
                                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                                    )
                                    .frame(width: 34, height: 34)
                                    .rotationEffect(.degrees(-90))
                                Text("\(Int(officer.approvalRate))%")
                                    .font(.system(size: 7.5, weight: .bold, design: .rounded))
                                    .foregroundStyle(LMSColors.textPrimary)
                                    .monospacedDigit()
                            }
                        }

                        if isCurrentlyAssigned {
                            HStack(spacing: 3) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10))
                                Text("Assigned")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(LMSColors.emerald)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(LMSColors.emerald.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.sm, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: LMSRadius.sm)
                                    .stroke(LMSColors.emerald.opacity(0.22), lineWidth: 0.5)
                            )
                        } else {
                            Button(action: {
                                HapticsManager.triggerImpact(style: .medium)
                                onAssign()
                            }) {
                                Group {
                                    if isProcessing {
                                        ProgressView()
                                            .tint(.white)
                                            .scaleEffect(0.78)
                                            .frame(width: 44, height: 28)
                                    } else {
                                        Text("Assign")
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
                                    }
                                }
                                .background(
                                    officer.capacityPercentage > 0.85
                                        ? LMSColors.coral
                                        : LMSColors.brandNavy
                                )
                                .clipShape(RoundedRectangle(cornerRadius: LMSRadius.sm, style: .continuous))
                            }
                            .disabled(isProcessing)
                            .buttonStyle(LMSPressableStyle())
                        }
                    }
                }
                .padding(LMSSpacing.lg)

                HStack(spacing: 0) {
                    OfficerMiniStat(
                        icon:  "star.fill",
                        value: String(format: "%.1f", officer.rating),
                        label: "Rating",
                        tint:  LMSColors.amber
                    )
                    Divider().frame(height: 22)
                    OfficerMiniStat(
                        icon:  "doc.text.fill",
                        value: "\(officer.loansProcessedYTD)",
                        label: "Processed",
                        tint:  LMSColors.actionBlue
                    )
                    Divider().frame(height: 22)
                    OfficerMiniStat(
                        icon:  "checkmark.seal.fill",
                        value: "\(Int(officer.approvalRate))%",
                        label: "Approval",
                        tint:  LMSColors.emerald
                    )
                    Divider().frame(height: 22)

                    OfficerMiniStat(
                        icon:  officer.capacityPercentage > 0.85
                                ? "exclamationmark.circle.fill"
                                : (officer.capacityPercentage > 0.60
                                    ? "clock.fill"
                                    : "checkmark.circle.fill"),
                        value: officer.capacityPercentage > 0.85
                                ? "Full"
                                : (officer.capacityPercentage > 0.60 ? "Busy" : "Free"),
                        label: "Capacity",
                        tint:  officer.capacityColor
                    )
                }
                .padding(.horizontal, LMSSpacing.lg)
                .padding(.vertical, LMSSpacing.sm)
                .background(LMSColors.background.opacity(0.55))
            }
        }
        .background(
            isCurrentlyAssigned
                ? LMSColors.emerald.opacity(0.04)
                : LMSColors.surfaceElevated
        )
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                .stroke(
                    isCurrentlyAssigned
                        ? LMSColors.emerald.opacity(0.22)
                        : LMSColors.separatorLight,
                    lineWidth: isCurrentlyAssigned ? 1.0 : 0.5
                )
        )
        .shadow(color: .black.opacity(isCurrentlyAssigned ? 0.05 : 0.02),
                radius: 8, x: 0, y: 3)
    }
}

private struct AssignmentSectionLabel: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundStyle(LMSColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, LMSSpacing.xs)
            .padding(.top, LMSSpacing.xs)
    }
}

struct AssignmentStatPill: View {
    let icon: String
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(tint)
                Text(value)
                    .font(.system(.callout, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)
                    .monospacedDigit()
            }
            Text(label)
                .font(.system(size: 9, design: .rounded))
                .foregroundStyle(LMSColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LMSSpacing.xs)
    }
}

private struct OfficerMiniStat: View {
    let icon: String
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(LMSColors.textPrimary)
                    .monospacedDigit()
                Text(label)
                    .font(.system(size: 7, design: .rounded))
                    .foregroundStyle(LMSColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
