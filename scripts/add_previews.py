#!/usr/bin/env python3
"""Append #Preview blocks to Swift view files that lack them."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "LoanManagementSystem"

CUSTOM = {
    "DashboardDesignSystem.swift": '''
#Preview("SectionContainer") {
    SectionContainer(title: "Sample", subtitle: "Preview subtitle") {
        Text("Section content")
    }
    .padding()
}
''',
    "CustomTextField.swift": '''
#Preview {
    @Previewable @State var text = ""
    CustomTextField(icon: "envelope", placeholder: "Email", text: $text)
        .padding()
}
''',
    "SecureInputField.swift": '''
#Preview {
    @Previewable @State var text = ""
    SecureInputField(placeholder: "Password", text: $text)
        .padding()
}
''',
    "PrimaryButton.swift": '''
#Preview {
    PrimaryButton(title: "Continue", action: {})
        .padding()
}
''',
    "CheckboxView.swift": '''
#Preview {
    @Previewable @State var checked = true
    CheckboxView(isChecked: $checked, label: "I agree to terms")
        .padding()
}
''',
    "DataRowView.swift": '''
#Preview {
    DataRowView(label: "Full Name", value: "Rahul Sharma", isVerified: true)
        .padding()
}
''',
    "DocumentUploadCardView.swift": '''
#Preview {
    DocumentUploadCardView(
        documentName: "PAN Card",
        status: .verified,
        onUpload: {},
        onDelete: {}
    )
    .padding()
}
''',
    "ProfileHeaderView.swift": '''
#Preview {
    ProfileHeaderView(
        name: "Rahul Sharma",
        id: "C-109482",
        completionPercentage: 72,
        isVerified: true,
        imageData: nil,
        onPhotoSelected: { _ in }
    )
    .padding()
}
''',
    "SectionCardView.swift": '''
#Preview {
    SectionCardView(title: "Personal Info", icon: "person.fill") {
        Text("Rahul Sharma")
        Text("rahul@example.com")
    }
    .padding()
}
''',
    "CustomerInsightCardView.swift": '''
#Preview {
    CustomerInsightCardView(profile: PreviewSupport.sampleBorrowerProfile)
        .padding()
}
''',
    "ManagerFloatingTabBar.swift": '''
#Preview {
    @Previewable @State var tab = 0
    ManagerFloatingTabBar(selectedTab: $tab, unreadChatCount: 2)
        .padding()
}
''',
    "ManagerTopToolbar.swift": '''
#Preview {
    ManagerTopToolbar(
        viewModel: PreviewSupport.managerViewModel,
        onNotificationPressed: {},
        onSettingsPressed: {},
        onProfilePressed: {},
        onSearchPressed: {}
    )
}
''',
    "ManagerApplicantActionSheet.swift": '''
#Preview {
    ManagerApplicantActionSheet(
        applicant: PreviewSupport.sampleManagerApplicant,
        actionType: .approve,
        viewModel: PreviewSupport.managerViewModel,
        onComplete: {}
    )
}
''',
    "ActivityFeedRow.swift": '''
#Preview {
    ActivityFeedRow(
        item: PreviewSupport.sampleActivityFeedItem,
        onMarkRead: {},
        onDismiss: {},
        onActionTapped: { _ in }
    )
    .padding()
}
''',
    "LoanHistoryRow.swift": '''
#Preview {
    LoanHistoryRow(
        app: PreviewSupport.loanOfficerViewModel.applications[0],
        onView: {},
        onCall: {},
        onFlag: {}
    )
    .padding()
}
''',
    "PortfolioSummaryCard.swift": '''
#Preview {
    PortfolioSummaryCard(viewModel: PreviewSupport.loanOfficerViewModel, onViewAllPressed: {})
        .padding()
}
''',
    "DocumentQueueView.swift": '''
#Preview {
    DocumentQueueView(
        viewModel: PreviewSupport.loanOfficerViewModel,
        onReviewTapped: { _ in }
    )
    .padding()
}
''',
    "DocumentReviewDetailView.swift": '''
#Preview {
    DocumentReviewDetailView(
        item: PreviewSupport.sampleDocumentQueueItem,
        viewModel: PreviewSupport.loanOfficerViewModel
    )
}
''',
    "LoanApplicationReviewDetailView.swift": '''
#Preview {
    NavigationStack {
        LoanApplicationReviewDetailView(
            applicationId: PreviewSupport.sampleLoanApplicationId,
            viewModel: PreviewSupport.loanOfficerViewModel
        )
    }
}
''',
    "DashboardTabView.swift": '''
#Preview {
    DashboardTabView(
        viewModel: PreviewSupport.loanOfficerViewModel,
        onDocumentSeeAllTapped: {},
        onManagerRespondTapped: { _ in },
        onQuickActionTapped: { _ in }
    )
    .previewLoanOfficerEnvironment()
}
''',
    "LoanOfficerDashboardView.swift": '''
#Preview {
    LoanOfficerDashboardView()
        .previewLoanOfficerEnvironment()
}
''',
    "OfficerQuickActionsView.swift": '''
#Preview {
    NavigationStack {
        OfficerQuickActionsView(
            viewModel: PreviewSupport.loanOfficerViewModel,
            onSystemAction: { _ in }
        )
        .padding()
    }
    .previewLoanOfficerEnvironment()
}
''',
    "QuickConsoleTabView.swift": '''
#Preview {
    QuickConsoleTabView(viewModel: PreviewSupport.loanOfficerViewModel) { _ in }
        .previewLoanOfficerEnvironment()
}
''',
    "QuickActionRowView.swift": '''
#Preview {
    QuickActionRowView(
        viewModel: PreviewSupport.loanOfficerViewModel,
        onActionTapped: { _ in }
    )
    .padding()
}
''',
    "ChatsFeedTabView.swift": '''
#Preview {
    ChatsFeedTabView(viewModel: PreviewSupport.loanOfficerViewModel)
        .previewLoanOfficerEnvironment()
}
''',
    "ManagerDashboardView.swift": '''
#Preview {
    ManagerDashboardView()
        .previewManagerEnvironment()
}
''',
    "AdminDashboardView.swift": '''
#Preview {
    AdminDashboardView()
        .previewAdminEnvironment()
}
''',
    "OnboardingQuestionnaireView.swift": '''
#Preview {
    OnboardingQuestionnaireView()
        .environmentObject(PreviewSupport.appState(role: .customer))
        .environmentObject(PreviewSupport.authManager)
}
''',
    "PortfolioMetricsSheet.swift": '''
#Preview {
    PortfolioMetricsSheet(viewModel: PreviewSupport.loanOfficerViewModel)
}
''',
}

def preview_for(path: Path, name: str) -> str:
    fname = path.name
    if fname in CUSTOM:
        return CUSTOM[fname]

    rel = str(path.relative_to(ROOT))

    if "EditForms" in rel or "ProfileDetails" in rel:
        return f'''
#Preview {{
    NavigationStack {{
        {name}(viewModel: PreviewSupport.borrowerProfileViewModel)
    }}
}}
'''
    if "Borrower/Views/Profile/ProfileView" in rel:
        return f'''
#Preview {{
    {name}()
        .previewBorrowerEnvironment()
}}
'''
    if "Borrower/Views/Auth" in rel or rel.endswith("MainTabView.swift"):
        return f'''
#Preview {{
    {name}()
        .previewBorrowerEnvironment()
}}
'''
    if "Borrower/Views/Dashboard" in rel or "Borrower/Views/History" in rel:
        return f'''
#Preview {{
    {name}(viewModel: PreviewSupport.dashboardViewModel)
        .previewBorrowerEnvironment()
}}
'''
    if "LoanApplication" in rel:
        return f'''
#Preview {{
    {name}(viewModel: PreviewSupport.loanApplicationViewModel)
        .previewBorrowerEnvironment()
}}
'''
    if "BankManager" in rel:
        if "Binding" in path.read_text() or "selectedTab" in name:
            return f'''
#Preview {{
    @Previewable @State var tab = 0
    {name}(viewModel: PreviewSupport.managerViewModel)
        .previewManagerEnvironment()
}}
'''
        return f'''
#Preview {{
    {name}(viewModel: PreviewSupport.managerViewModel)
        .previewManagerEnvironment()
}}
'''
    if "LoanOfficer" in rel:
        if "viewModel" in path.read_text()[:2000].lower() or "ViewModel" in path.read_text()[:3000]:
            if "onAction" in path.read_text() or "onReview" in path.read_text() or "onSee" in path.read_text() or "onView" in path.read_text() or "onManager" in path.read_text() or "onQuick" in path.read_text() or "onDocument" in path.read_text() or "onSystem" in path.read_text() or "onComplete" in path.read_text() or "onOpen" in path.read_text() or "onDownload" in path.read_text() or "onSubmit" in path.read_text():
                pass  # handled in CUSTOM or need closure
        return f'''
#Preview {{
    {name}(viewModel: PreviewSupport.loanOfficerViewModel)
        .previewLoanOfficerEnvironment()
}}
'''

    return f'''
#Preview {{
    {name}()
        .padding()
}}
'''

def main():
    files = []
    for p in ROOT.rglob("*.swift"):
        if "ViewModels" in str(p):
            continue
        if "/Views/" in str(p) or p.name.endswith("View.swift"):
            if p.parent.name == "Views" or "/Views/" in str(p):
                files.append(p)

    for path in sorted(files):
        text = path.read_text()
        if "#Preview" in text or "PreviewProvider" in text:
            continue
        match = re.search(r"^struct\s+(\w+)\s*:\s*View\b", text, re.M)
        if not match:
            continue
        name = match.group(1)
        snippet = preview_for(path, name)
        if not snippet.strip():
            continue
        new_text = text.rstrip() + "\n" + snippet
        path.write_text(new_text)
        print(f"Added preview: {path.relative_to(ROOT)}")

if __name__ == "__main__":
    main()
