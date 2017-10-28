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

enum ClassificationLabel: String {
    case sfw = "SFW"
    case nsfw = "NSFW"
}

struct ClassificationResult: CustomStringConvertible{
    let label: ClassificationLabel
    let confidence: Double

    init(label: ClassificationLabel, confidence: Double) {
        self.label = label
        self.confidence = confidence
    }

    var description: String {
        return "Label: \(label)\nConfidence: \(confidence)"
    }
}

protocol ClassificationServiceDelegate: class {
    func classificationService(_ service: ClassificationService, didStartClassifying image: UIImage, with identifier: Any?)
    func classificationService(_ service: ClassificationService, didFinishClassifying results: [ClassificationResult]?, with identifier: Any?)
    func classificationService(_ service: ClassificationService, didFailedClassifying error: Error?, with identifier: Any?)
}

class ClassificationService {

    /// MARK: - Properties

    weak var delegate: ClassificationServiceDelegate?
    var classifying: Bool = false
    var currentIdentifier: Any? = nil

    lazy var model: VNCoreMLModel = {
        do {
            let model = try VNCoreMLModel(for: Nudity().model)
            return model
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()

    lazy var classificationRequest: VNCoreMLRequest = {
        let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
            self?.processClassifications(for: request, error: error)
        })
        request.imageCropAndScaleOption = .centerCrop
        return request
    }()


    /// MARK: - Classifications

    func classify(_ image: UIImage, for identifier: Any?) {
        if classifying {
            return
        }

        classifying = true
        currentIdentifier = identifier
        delegate?.classificationService(self, didStartClassifying: image, with: identifier)

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
                self.classifying = false
                self.currentIdentifier = nil
            }
        }
    }


    // MARK: - Private

    private func processClassifications(for request: VNRequest, error: Error?) {
        classifying = false

        guard let results = request.results else {
            print("Unable to classify image.\n\(error!.localizedDescription)")
            delegate?.classificationService(self, didFailedClassifying: error, with: currentIdentifier)
            currentIdentifier = nil
            return
        }

        // The `results` will always be `VNClassificationObservation`s, as specified by the Core ML model in this project.
        let classifications = results as! [VNClassificationObservation]

        if classifications.isEmpty {
            print ("Nothing recognized.")
            delegate?.classificationService(self, didFinishClassifying: nil, with: currentIdentifier)
            currentIdentifier = nil
        } else {
            let topClassifications = classifications.prefix(2)
            let classificationResults = topClassifications.map { classification in
                return ClassificationResult(label: ClassificationLabel(rawValue: classification.identifier)!, confidence: Double(classification.confidence))
            }
            delegate?.classificationService(self, didFinishClassifying: classificationResults, with: currentIdentifier)
            currentIdentifier = nil
        }
    }
}
