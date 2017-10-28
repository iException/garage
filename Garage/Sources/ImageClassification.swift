//
//  ImageClassification.swift
//  Garage
//
//  Created by Yiming Tang on 10/28/17.
//  Copyright © 2017 Baixing. All rights reserved.
//

import UIKit
import CoreML
import Vision
import ImageIO

enum Classification: String {
    case sfw = "SFW"
    case nsfw = "NSFW"
}

struct ClassificationResult {
    let possibleClassification : Classification
    let probability : Double
}

protocol ClassificationServiceDelegate: class {
    func classificationService(_ service: ClassificationService, didStartClassifying image: UIImage)
    func classificationService(_ service: ClassificationService, didFinishClassifying result: ClassificationResult?)
    func classificationService(_ service: ClassificationService, didFailedClassifying error: Error?)
}

class ClassificationService {

    /// MARK: - Properties

    weak var delegate: ClassificationServiceDelegate?

    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: Nudity().model)
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()


    /// MARK: - Classifications

    func classify(_ image: UIImage) {
        delegate?.classificationService(self, didStartClassifying: image)

        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }

        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                /*
                 This handler catches general image processing errors. The `classificationRequest`'s
                 completion handler `processClassifications(_:error:)` catches errors specific
                 to processing that request.
                 */
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }


    // MARK: - Private

    private func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results else {
                print("Unable to classify image.\n\(error!.localizedDescription)")
                self.delegate?.classificationService(self, didFailedClassifying: error)
                return
            }

            // The `results` will always be `VNClassificationObservation`s, as specified by the Core ML model in this project.
            let classifications = results as! [VNClassificationObservation]

            if classifications.isEmpty {
                print ("Nothing recognized.")
                self.delegate?.classificationService(self, didFinishClassifying: nil)
            } else {
                // Display top classifications ranked by confidence in the UI.
                let topClassifications = classifications.prefix(2)
                let descriptions = topClassifications.map { classification in
                    // Formats the classification for display; e.g. "(0.37) cliff, drop, drop-off".
                    return String(format: "  (%.2f) %@", classification.confidence, classification.identifier)
                }
                print ("Classification:\n" + descriptions.joined(separator: "\n"))
            }
        }
    }
}
