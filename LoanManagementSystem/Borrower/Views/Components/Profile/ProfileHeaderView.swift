import SwiftUI
import PhotosUI

struct ProfileHeaderView: View {
    var name: String
    var id: String
    var completionPercentage: Int
    var isVerified: Bool
    var imageData: Data?
    var onPhotoSelected: (Data) -> Void
    
    @State private var selectedItem: PhotosPickerItem? = nil
    
    var body: some View {
        HStack(spacing: 20) {
            // Circular Avatar with Progress Ring and Photo Selection
            PhotosPicker(selection: $selectedItem, matching: .images) {
                ZStack {
                    // Background Track
                    Circle()
                        .stroke(Color.AppTheme.textSecondary.opacity(0.15), lineWidth: 3.5)
                        .frame(width: 78, height: 78)
                    
                    // Progress Arc
                    Circle()
                        .trim(from: 0.0, to: CGFloat(completionPercentage) / 100.0)
                        .stroke(
                            Color.AppTheme.primary,
                            style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                        )
                        .frame(width: 78, height: 78)
                        .rotationEffect(.degrees(-90))
                    
                    // Avatar Image
                    Group {
                        if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .foregroundStyle(Color.AppTheme.primary)
                        }
                    }
                    .frame(width: 70, height: 70)
                    .background(Circle().fill(Color.AppTheme.secondary.opacity(0.8)))
                    .clipShape(Circle())
                    
                    // Plus sign badge for photo addition (bottom right)
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.AppTheme.primary))
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                        .offset(x: 26, y: 26)
                    
                    // Verification Badge (moved to top right so they don't overlap)
                    if isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.AppTheme.success)
                            .background(Circle().fill(Color.white))
                            .offset(x: 26, y: -26)
                    }
                }
            }
            .buttonStyle(.plain)
            .onChange(of: selectedItem) { _, newItem in
                if let newItem {
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self) {
                            await MainActor.run {
                                onPhotoSelected(data)
                            }
                        }
                    }
                }
            }
            .frame(width: 82, height: 82)
            
            // Name, ID and Completion Status
            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.AppTheme.textPrimary)
                
                Text("Borrower ID: \(id)")
                    .font(Font.AppTheme.caption)
                    .foregroundStyle(Color.AppTheme.textSecondary)
                
                // Completion Tag
                HStack(spacing: 4) {
                    Circle()
                        .fill(completionPercentage == 100 ? Color.AppTheme.success : Color.AppTheme.primary)
                        .frame(width: 6, height: 6)
                    
                    Text("\(completionPercentage)% Setup")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(completionPercentage == 100 ? Color.AppTheme.success : Color.AppTheme.primary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill((completionPercentage == 100 ? Color.AppTheme.success : Color.AppTheme.primary).opacity(0.12))
                )
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
    }
}

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
