import SwiftUI

struct ComplaintDetailView: View {
    @ObservedObject var viewModel: ComplaintViewModel
    let ticketId: UUID
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddNote = false
    @State private var showingAssignStaff = false
    @State private var showingAssignTeam = false
    @State private var showingStatusPicker = false
    @State private var newNote = ""
    @State private var newStaff = ""
    @State private var newTeam = ""
    
    private var ticket: ComplaintTicket? {
        viewModel.tickets.first(where: { $0.id == ticketId })
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            LMSColors.background.ignoresSafeArea()
            
            if let ticket = ticket {
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // Header Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                // Origin Badge
                                Label(ticket.origin.rawValue, systemImage: ticket.origin.iconName)
                                    .font(LMSFont.caption2.weight(.bold))
                                    .foregroundStyle(ticket.origin.tint)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(ticket.origin.tint.opacity(0.1), in: Capsule())
                                
                                Spacer()
                                
                                Text(ticket.priority.rawValue.uppercased())
                                    .font(LMSFont.caption2.weight(.bold))
                                    .foregroundStyle(ticket.priority.color)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(ticket.priority.color.opacity(0.12), in: Capsule())
                                
                                Text(ticket.status.rawValue)
                                    .font(LMSFont.caption.weight(.bold))
                                    .foregroundStyle(ticket.status.color)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(ticket.status.color.opacity(0.12), in: Capsule())
                            }
                            
                            Text(ticket.ticketId)
                                .font(LMSFont.subheadline)
                                .foregroundStyle(LMSColors.textSecondary)
                            
                            Text(ticket.title)
                                .font(LMSFont.title.weight(.bold))
                                .foregroundStyle(LMSColors.textPrimary)
                            
                            HStack(spacing: 16) {
                                HStack(spacing: 4) {
                                    Image(systemName: ticket.category.iconName)
                                        .font(.system(size: 12))
                                        .foregroundStyle(LMSColors.textTertiary)
                                    Text(ticket.category.rawValue)
                                        .font(LMSFont.caption)
                                        .foregroundStyle(LMSColors.textSecondary)
                                }
                                Text("•").foregroundStyle(LMSColors.textTertiary)
                                Text(ticket.dateRaised.formatted(date: .abbreviated, time: .shortened))
                                    .font(LMSFont.caption)
                                    .foregroundStyle(LMSColors.textTertiary)
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lmsCardElevated()
                        .padding(.horizontal, LMSSpacing.screenHorizontal)
                        .padding(.top, 16)
                        
                        // Operational Details
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Details")
                                .font(LMSFont.headline)
                                .foregroundStyle(LMSColors.textPrimary)
                            
                            if let borrower = ticket.borrowerName {
                                detailRow(icon: "person.fill", title: "Borrower", value: borrower)
                                Divider().background(LMSColors.separatorLight)
                            }
                            
                            detailRow(icon: "building.2.fill", title: "Branch", value: ticket.branchName)
                            Divider().background(LMSColors.separatorLight)
                            
                            detailRow(
                                icon: "person.badge.shield.checkmark.fill",
                                title: "Assigned Manager",
                                value: ticket.assignedManager ?? "Unassigned",
                                valueColor: ticket.assignedManager == nil ? LMSColors.coral : LMSColors.textPrimary
                            )
                            Divider().background(LMSColors.separatorLight)
                            
                            detailRow(
                                icon: "person.3.fill",
                                title: "Assigned Team",
                                value: ticket.assignedTeam ?? "Unassigned",
                                valueColor: ticket.assignedTeam == nil ? LMSColors.coral : LMSColors.textPrimary
                            )
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lmsCard()
                        .padding(.horizontal, LMSSpacing.screenHorizontal)
                        
                        // Description
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Description")
                                .font(LMSFont.headline)
                                .foregroundStyle(LMSColors.textPrimary)
                            Text(ticket.description)
                                .font(LMSFont.body)
                                .foregroundStyle(LMSColors.textSecondary)
                                .lineSpacing(4)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lmsCard()
                        .padding(.horizontal, LMSSpacing.screenHorizontal)
                        
                        // Internal Remarks
                        if ticket.managerNotes != nil || ticket.adminRemarks != nil {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Internal Remarks")
                                    .font(LMSFont.headline)
                                    .foregroundStyle(LMSColors.textPrimary)
                                
                                if let notes = ticket.managerNotes {
                                    remarkBubble(label: "Manager Notes", text: notes, color: LMSColors.brandNavy)
                                }
                                if let remarks = ticket.adminRemarks {
                                    remarkBubble(label: "Admin Remarks", text: remarks, color: LMSColors.coral)
                                }
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lmsCard()
                            .padding(.horizontal, LMSSpacing.screenHorizontal)
                        }
                        
                        // Timeline
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Activity Timeline")
                                .font(LMSFont.headline)
                                .foregroundStyle(LMSColors.textPrimary)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 0) {
                                ForEach(ticket.timeline.indices, id: \.self) { index in
                                    let event = ticket.timeline[index]
                                    let isLast = index == ticket.timeline.count - 1
                                    
                                    HStack(alignment: .top, spacing: 16) {
                                        VStack(spacing: 0) {
                                            Circle()
                                                .fill(index == 0 ? LMSColors.brandNavy : LMSColors.separator)
                                                .frame(width: 12, height: 12)
                                            if !isLast {
                                                Rectangle()
                                                    .fill(LMSColors.separatorLight)
                                                    .frame(width: 2)
                                            }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(event.action)
                                                    .font(LMSFont.subheadline.weight(.semibold))
                                                    .foregroundStyle(LMSColors.textPrimary)
                                                Spacer()
                                                if let user = event.user {
                                                    Text(user)
                                                        .font(LMSFont.caption2)
                                                        .foregroundStyle(LMSColors.brandNavy)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(LMSColors.brandNavy.opacity(0.1), in: Capsule())
                                                }
                                            }
                                            Text(event.date.formatted(date: .abbreviated, time: .shortened))
                                                .font(LMSFont.caption)
                                                .foregroundStyle(LMSColors.textTertiary)
                                            if let note = event.note {
                                                Text(note)
                                                    .font(LMSFont.footnote)
                                                    .foregroundStyle(LMSColors.textSecondary)
                                                    .padding(.top, 2)
                                            }
                                        }
                                        .padding(.bottom, isLast ? 0 : 20)
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lmsCard()
                        .padding(.horizontal, LMSSpacing.screenHorizontal)
                        
                        Spacer().frame(height: 200)
                    }
                }
                
                // Floating Action Toolbar
                VStack(spacing: 12) {
                    Divider().background(LMSColors.separatorLight)
                    
                    // Secondary Actions
                    HStack(spacing: 10) {
                        secondaryButton(label: "Add Note", icon: "note.text") { showingAddNote = true }
                        secondaryButton(label: "Assign Staff", icon: "person.badge.plus") { showingAssignStaff = true }
                        secondaryButton(label: "Assign Team", icon: "person.3.fill") { showingAssignTeam = true }
                        secondaryButton(label: "Status", icon: "arrow.triangle.2.circlepath") { showingStatusPicker = true }
                    }
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
                    
                    // Primary Actions
                    HStack(spacing: 12) {
                        if ticket.status != .resolved && ticket.status != .closed {
                            Button {
                                viewModel.updateStatus(for: ticket.id, to: .resolved, user: "Admin")
                                dismiss()
                            } label: {
                                Text("Mark Resolved")
                                    .font(LMSFont.button)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(LMSColors.emerald, in: RoundedRectangle(cornerRadius: LMSRadius.md))
                            }
                            .buttonStyle(LMSPressableStyle())
                        }
                        
                        if ticket.status != .escalated && ticket.status != .resolved && ticket.status != .closed {
                            Button {
                                viewModel.escalate(id: ticket.id, user: "Manager")
                            } label: {
                                Text("Escalate")
                                    .font(LMSFont.button)
                                    .foregroundStyle(LMSColors.coral)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(LMSColors.coral.opacity(0.12), in: RoundedRectangle(cornerRadius: LMSRadius.md))
                            }
                            .buttonStyle(LMSPressableStyle())
                        }
                    }
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
                    .padding(.bottom, 16)
                }
                .background(.ultraThinMaterial)
                
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundStyle(LMSColors.textTertiary)
                    Text("Ticket Not Found")
                        .font(LMSFont.headline)
                        .foregroundStyle(LMSColors.textSecondary)
                }
            }
        }
        .navigationTitle("Ticket Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Add Internal Note", isPresented: $showingAddNote) {
            TextField("Enter note...", text: $newNote)
            Button("Cancel", role: .cancel) { newNote = "" }
            Button("Save") {
                viewModel.addNote(id: ticketId, note: newNote, user: "Staff", isAdmin: true)
                newNote = ""
            }
        }
        .alert("Assign Support Staff", isPresented: $showingAssignStaff) {
            TextField("Enter staff name...", text: $newStaff)
            Button("Cancel", role: .cancel) { newStaff = "" }
            Button("Assign") {
                viewModel.assignManager(id: ticketId, managerName: newStaff, assignedBy: "Admin")
                newStaff = ""
            }
        }
        .alert("Assign Technical Team", isPresented: $showingAssignTeam) {
            TextField("Enter team name...", text: $newTeam)
            Button("Cancel", role: .cancel) { newTeam = "" }
            Button("Assign") {
                viewModel.assignTeam(id: ticketId, teamName: newTeam, assignedBy: "Admin")
                newTeam = ""
            }
        }
        .confirmationDialog("Update Status", isPresented: $showingStatusPicker, titleVisibility: .visible) {
            ForEach(ComplaintStatus.allCases) { status in
                Button(status.rawValue) {
                    viewModel.updateStatus(for: ticketId, to: status, user: "Admin")
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    // MARK: - Helper Views
    private func detailRow(icon: String, title: String, value: String, valueColor: Color = LMSColors.textPrimary) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(LMSColors.textTertiary)
                .frame(width: 20)
            Text(title)
                .font(LMSFont.subheadline)
                .foregroundStyle(LMSColors.textSecondary)
            Spacer()
            Text(value)
                .font(LMSFont.subheadline.weight(.semibold))
                .foregroundStyle(valueColor)
        }
    }
    
    private func remarkBubble(label: String, text: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(LMSFont.caption.weight(.bold))
                .foregroundStyle(color)
            Text(text)
                .font(LMSFont.subheadline)
                .foregroundStyle(LMSColors.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.05), in: RoundedRectangle(cornerRadius: LMSRadius.md))
    }
    
    private func secondaryButton(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
            }
            .foregroundStyle(LMSColors.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(LMSColors.surfaceElevated, in: RoundedRectangle(cornerRadius: LMSRadius.sm))
            .overlay(RoundedRectangle(cornerRadius: LMSRadius.sm).stroke(LMSColors.separator, lineWidth: 0.5))
        }
        .buttonStyle(LMSPressableStyle())
    }
}

#Preview {
    NavigationStack {
        ComplaintDetailView(viewModel: ComplaintViewModel(), ticketId: ComplaintViewModel().tickets.first!.id)
    }
    .preferredColorScheme(.dark)
}
