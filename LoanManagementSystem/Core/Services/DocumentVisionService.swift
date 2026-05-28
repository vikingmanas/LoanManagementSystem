import Foundation
import UIKit
@preconcurrency import Vision

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

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            let observations = request.results ?? []
            let candidates = observations.compactMap { $0.topCandidates(1).first }
            let text = candidates.map(\.string).joined(separator: " ")
            let confidence = candidates.isEmpty ? 0 : candidates.map(\.confidence).reduce(0, +) / Float(candidates.count)
            return DocumentVisionResult(extractedText: text, confidence: confidence)
        } catch {
            return nil
        }
    }
}
