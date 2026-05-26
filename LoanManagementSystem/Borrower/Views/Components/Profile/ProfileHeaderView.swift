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
        VStack(spacing: 16) {
            // Native circular avatar
            PhotosPicker(selection: $selectedItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.secondary.opacity(0.3))
                        }
                    }
                    .frame(width: 90, height: 90)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(.separator), lineWidth: 0.5))
                    
                    // Edit button badge
                    Image(systemName: "camera.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
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
            
            // Name and Details
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
                
                Text("Borrower ID: \(id)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // Native-style progress indicator
                if completionPercentage < 100 {
                    HStack(spacing: 8) {
                        ProgressView(value: Double(completionPercentage), total: 100)
                            .progressViewStyle(.linear)
                            .frame(width: 100)
                            .tint(.blue)
                        
                        Text("\(completionPercentage)% Profile Setup")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
