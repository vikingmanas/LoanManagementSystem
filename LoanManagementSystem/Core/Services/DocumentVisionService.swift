import Foundation
import UIKit
import Vision

struct DocumentVisionResult {
    let extractedText: String
    let confidence: Float

    var statusMessage: String {
        guard !extractedText.isEmpty else {
            return "No readable text detected. Upload a clearer scan."
        }

        if confidence >= 0.70 {
            return "Document text detected with high confidence."
        }
        return "Document text detected, but the scan may need manual review."
    }
}

enum DocumentVisionService {
    static func analyzeImage(at url: URL) async -> DocumentVisionResult? {
        guard let image = UIImage(contentsOfFile: url.path),
              let cgImage = image.cgImage else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let candidates = observations.compactMap { $0.topCandidates(1).first }
                let text = candidates.map(\.string).joined(separator: " ")
                let confidence = candidates.isEmpty ? 0 : candidates.map(\.confidence).reduce(0, +) / Float(candidates.count)
                continuation.resume(returning: DocumentVisionResult(extractedText: text, confidence: confidence))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                try? handler.perform([request])
            }
        }
    }
}
