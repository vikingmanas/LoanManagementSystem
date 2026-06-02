import os
import re

files_to_strip = [
    "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/LoanManagementSystem/Core/Views/StaffLoginView.swift",
    "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/LoanManagementSystem/Borrower/Views/Dashboard/CustomerInsightCardView.swift",
    "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/LoanManagementSystem/Borrower/Views/Profile/ProfileDetails/LinkedBankAccountsDetailView.swift",
    "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/LoanManagementSystem/Borrower/Views/History/HistoryTabView.swift",
    "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/LoanManagementSystem/Borrower/Views/EditForms/EditAddressInfoView.swift",
    "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/LoanManagementSystem/Borrower/Views/EditForms/EditEmploymentView.swift",
    "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/LoanManagementSystem/Borrower/Views/EditForms/EditLoanOverviewView.swift",
    "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/LoanManagementSystem/LoanOfficer/Views/KPIGridView.swift",
    "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/LoanManagementSystem/LoanOfficer/Views/PortfolioSummaryCard.swift",
    "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/LoanManagementSystem/LoanOfficer/Views/ActivityFeedView.swift",
    "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/LoanManagementSystem/LoanOfficer/Views/LoanOfficerDetailedAnalyticsSheet.swift",
    "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/LoanManagementSystem/LoanOfficer/Views/LoanOfficerChartView.swift",
    "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/LoanManagementSystem/LoanOfficer/Views/ProcessedLoansView.swift",
    "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/LoanManagementSystem/LoanOfficer/Views/ActivityFeedRow.swift",
    "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/LoanManagementSystem/LoanOfficer/Views/PortfolioMetricsSheet.swift",
    "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/LoanManagementSystem/LoanOfficer/Views/QuickActionRowView.swift",
    "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/LoanManagementSystem/BankManager/Views/Applicants/ManagerApplicantDetailView.swift",
    "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/LoanManagementSystem/BankManager/Views/Applicants/ApplicationAssignmentSheet.swift",
    "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/LoanManagementSystem/BankManager/Views/Applicants/ManagerApplicantActionSheet.swift",
    "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/LoanManagementSystem/BankManager/Views/Applicants/ManagerApplicantsTabView.swift",
    "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/LoanManagementSystem/BankManager/Views/Dashboard/ManagerReportsView.swift",
    "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/LoanManagementSystem/BankManager/Views/Dashboard/ManagerApprovalQueueView.swift",
    "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/LoanManagementSystem/BankManager/Views/Dashboard/ManagerBranchTabView.swift",
    "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/LoanManagementSystem/BankManager/Views/Dashboard/ManagerDashboardTabView.swift",
    "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/LoanManagementSystem/BankManager/Views/Dashboard/ManagerAnalyticsView.swift",
    "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/LoanManagementSystem/BankManager/Views/Profile/ManagerProfileView.swift",
    "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/LoanManagementSystem/BankManager/Views/Profile/ManagerNotificationsView.swift",
    "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/LoanManagementSystem/BankManager/Views/Communication/ManagerCommunicationTabView.swift"
]

def strip_preview(content):
    # Regex to match #Preview block and everything after it (since they are usually at the end)
    # Sometimes there are multiple previews, so let's match the first #Preview and strip to EOF.
    # Wait, some files might have other things at the end? Usually #Preview is the very last thing.
    
    # A safer approach is to find #Preview, and match balancing curly braces.
    lines = content.splitlines()
    out_lines = []
    in_preview = False
    brace_count = 0
    
    for line in lines:
        if not in_preview:
            if line.strip().startswith("#Preview"):
                in_preview = True
                brace_count = line.count("{") - line.count("}")
                if brace_count <= 0 and "{" in line: # single line preview
                    in_preview = False
            else:
                out_lines.append(line)
        else:
            brace_count += line.count("{") - line.count("}")
            if brace_count <= 0:
                in_preview = False
                
    return "\n".join(out_lines) + "\n"

for fpath in files_to_strip:
    try:
        with open(fpath, "r") as f:
            content = f.read()
        new_content = strip_preview(content)
        with open(fpath, "w") as f:
            f.write(new_content)
        print(f"Stripped {fpath}")
    except Exception as e:
        print(f"Error processing {fpath}: {e}")
