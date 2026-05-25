import SwiftUI

struct DocumentUploadSheet: View {
    let documentName: String
    let onUpload: (String, BorrowerDocumentUploadSource) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var uploadSource: BorrowerDocumentUploadSource = .camera
    @State private var fileName: String = ""
    
    // Camera States
    @State private var hasCaptured: Bool = false
    @State private var capturedImageName: String = ""
    
    // Gallery States
    @State private var selectedIndex: Int? = nil

    private var isValidFormat: Bool {
        let name = fileName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return name.hasSuffix(".pdf") || name.hasSuffix(".png")
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 4) {
                Text(documentName)
                    .font(LMSFont.title3)
                    .foregroundStyle(LMSColors.textPrimary)
                Text("Select source and upload in PDF or PNG format.")
                    .font(LMSFont.caption)
                    .foregroundStyle(LMSColors.textSecondary)
            }
            .padding(.top, 16)

            // Source Selector Segmented Control
            Picker("Source", selection: $uploadSource) {
                Text("Camera").tag(BorrowerDocumentUploadSource.camera)
                Text("Gallery").tag(BorrowerDocumentUploadSource.gallery)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)

            // Content Area based on Selection
            Group {
                switch uploadSource {
                case .camera:
                    CameraSimulationView(
                        hasCaptured: $hasCaptured,
                        capturedImageName: $capturedImageName,
                        fileName: $fileName
                    )
                case .gallery:
                    GallerySimulationView(
                        selectedIndex: $selectedIndex,
                        fileName: $fileName
                    )
                default:
                    EmptyView()
                }
            }
            .frame(height: 220)
            .padding(.horizontal, 16)

            // Filename input & Validation Area
            VStack(alignment: .leading, spacing: 8) {
                Text("FILE NAME")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(LMSColors.textSecondary)
                
                HStack(spacing: 8) {
                    TextField("Enter file name or select one above...", text: $fileName)
                        .font(LMSFont.body)
                        .padding(12)
                        .background(LMSColors.surfaceTertiary, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(LMSColors.separatorLight, lineWidth: 1)
                        )
                    
                    if !fileName.isEmpty {
                        Image(systemName: isValidFormat ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.title3)
                            .foregroundStyle(isValidFormat ? Color.lmsEmerald : Color.lmsCoral)
                    }
                }

                // Format Warning Banner
                if !fileName.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: isValidFormat ? "checkmark.seal.fill" : "xmark.octagon.fill")
                        Text(isValidFormat ? "Supported format recognized (.pdf / .png)" : "Invalid format! Only PDF or PNG are allowed.")
                            .font(LMSFont.caption2.weight(.semibold))
                    }
                    .foregroundStyle(isValidFormat ? Color.lmsEmerald : Color.lmsCoral)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        (isValidFormat ? Color.lmsEmerald : Color.lmsCoral).opacity(0.1),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                }
            }
            .padding(.horizontal, 16)

            Spacer()

            // Confirm Upload Button
            Button(action: {
                onUpload(fileName, uploadSource)
                dismiss()
            }) {
                HStack {
                    Spacer()
                    Text("Confirm Upload")
                        .font(LMSFont.button)
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(isValidFormat ? LMSColors.brandNavy : Color.gray.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!isValidFormat)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .presentationDetents([.height(580)])
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: 22))
    }
}

// MARK: - Camera Simulation View
struct CameraSimulationView: View {
    @Binding var hasCaptured: Bool
    @Binding var capturedImageName: String
    @Binding var fileName: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )

            if hasCaptured {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 54))
                        .foregroundStyle(.white)

                    Text("Photo Captured!")
                        .font(LMSFont.headline)
                        .foregroundStyle(.white)
                    
                    Button(action: {
                        hasCaptured = false
                        fileName = ""
                    }) {
                        Text("Retake Photo")
                            .font(LMSFont.caption.bold())
                            .foregroundStyle(Color.lmsActionBlue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.15), in: Capsule())
                    }
                }
            } else {
                VStack(spacing: 14) {
                    // Shutter frame
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.4), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [8, 8]))
                            .frame(width: 140, height: 100)
                        
                        Image(systemName: "camera.metering.matrix")
                            .font(.system(size: 24))
                            .foregroundStyle(.white.opacity(0.3))
                    }

                    Button(action: {
                        let rand = Int.random(in: 1000...9999)
                        capturedImageName = "doc_snapshot_\(rand).png"
                        fileName = capturedImageName
                        hasCaptured = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                            Text("Click Photo")
                        }
                        .font(LMSFont.button)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(LMSColors.brandNavy, in: Capsule())
                    }
                }
            }
        }
    }
}

// MARK: - Gallery Simulation View
struct GallerySimulationView: View {
    @Binding var selectedIndex: Int?
    @Binding var fileName: String

    let items = [
        (name: "Aadhaar_Scan.png", label: "Aadhaar Scan", ext: "PNG"),
        (name: "PAN_Copy.png", label: "PAN Copy", ext: "PNG"),
        (name: "UtilityBill.pdf", label: "Utility Bill", ext: "PDF"),
        (name: "RentAgreement.pdf", label: "Rent Contract", ext: "PDF"),
        (name: "SalarySlip_May.jpg", label: "May Salary Slip", ext: "JPG"), // Invalid to test validation
        (name: "Doc_Draft.doc", label: "Doc Draft", ext: "DOC") // Invalid to test validation
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Simulated Photos & Files:")
                .font(LMSFont.caption)
                .foregroundStyle(LMSColors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<items.count, id: \.self) { idx in
                        let item = items[idx]
                        let isSelected = selectedIndex == idx
                        let isExtValid = item.name.hasSuffix(".png") || item.name.hasSuffix(".pdf")

                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(LMSColors.surfaceTertiary)
                                    .frame(width: 100, height: 90)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(isSelected ? LMSColors.brandNavy : Color.clear, lineWidth: 2)
                                    )

                                VStack(spacing: 4) {
                                    Image(systemName: item.name.hasSuffix(".pdf") ? "doc.richtext.fill" : "photo.fill")
                                        .font(.title2)
                                        .foregroundStyle(isSelected ? LMSColors.brandNavy : LMSColors.textSecondary)
                                    
                                    Text(item.ext)
                                        .font(.system(size: 9, weight: .black))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(isExtValid ? Color.lmsEmerald : Color.lmsCoral, in: Capsule())
                                }
                            }

                            Text(item.label)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(LMSColors.textPrimary)
                                .lineLimit(1)
                                .frame(width: 100)
                        }
                        .scaleEffect(isSelected ? 1.03 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isSelected)
                        .onTapGesture {
                            selectedIndex = idx
                            fileName = item.name
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}
