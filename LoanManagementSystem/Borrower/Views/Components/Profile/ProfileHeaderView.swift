import SwiftUI
import PhotosUI

struct ProfileHeaderView: View {
    private let avatarSize: CGFloat = 120

    var name: String
    var id: String
    var completionPercentage: Int
    var isVerified: Bool
    var imageData: Data?
    var onPhotoSelected: (Data) -> Void
    
    @State private var selectedItem: PhotosPickerItem? = nil
    
    var body: some View {
        VStack(spacing: 16) {

            PhotosPicker(selection: $selectedItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    avatarImage
                    
                    Image(systemName: "camera.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.accentColor))
                        .overlay(Circle().stroke(Color(.systemGroupedBackground), lineWidth: 2))
                        .shadow(color: .black.opacity(0.1), radius: 2)
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
            
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text(name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    if isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.blue)
                            .font(.system(size: 16))
                    }
                }
                
                if completionPercentage < 100 {
                    VStack(spacing: 6) {
                        ProgressView(value: Double(completionPercentage), total: 100)
                            .progressViewStyle(.linear)
                            .frame(width: 140)
                            .tint(.blue)
                        
                        Text("\(completionPercentage)% Profile Setup")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 18)
    }

    @ViewBuilder
    private var avatarImage: some View {
        if let imageData = imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: avatarSize, height: avatarSize)
                .clipped()
                .clipShape(Circle())
                .overlay(Circle().stroke(Color(.separator), lineWidth: 0.5))
        } else {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.secondary.opacity(0.3))
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color(.separator), lineWidth: 0.5))
        }
    }
}

#Preview {
    ProfileHeaderView(
        name: "Demo User",
        id: "1531491B-E16B-48F2",
        completionPercentage: 26,
        isVerified: true,
        imageData: nil,
        onPhotoSelected: { _ in }
    )
}
