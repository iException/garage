//
//  ViewController.swift
//  Garage
//
//  Created by Yiming Tang on 10/27/17.
//  Copyright © 2017 Baixing. All rights reserved.
//

import UIKit
import Photos

final class ViewController: UIViewController {

    // MARK: - Properties
    let targetSize = CGSize(width: 224, height: 224)
    let cachingImageManager = PHCachingImageManager()

    var assets: [PHAsset] = [] {
        willSet {
            cachingImageManager.stopCachingImagesForAllAssets()
        }

        didSet {
            cachingImageManager.startCachingImages(for: self.assets, targetSize: targetSize, contentMode: .aspectFit, options: nil)
        }
    }

    private let button: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Scan", for: .normal)
        button.setTitleColor(#colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1), for: .normal)
        return button
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private let textLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.textAlignment = .center
        textLabel.textColor = #colorLiteral(red: 0.05882352963, green: 0.180392161, blue: 0.2470588237, alpha: 1)
        return textLabel
    }()

    lazy var classificationService: ClassificationService = {
        let service = ClassificationService()
        service.delegate = self
        return service
    }()


    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        button.addTarget(self, action: #selector(scan(_:)), for: .touchUpInside)
        view.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        view.addSubview(imageView)
        view.addSubview(textLabel)
        view.addSubview(button)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            textLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10.0),
            textLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            button.topAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: 10.0),
            button.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
        ])
    }


    // MARK: - Actions

    @objc func scan(_ sender: UIButton?) {
        PHPhotoLibrary.requestAuthorization({ (status) in
            if (status == .authorized) {
                DispatchQueue.main.async {
                    self.loadAllPhotos()
                    self.classifyAllPhotosWithVision()
//                    self.classifyAllPhotosWithCoreMLOnly()
                }
            } else {
                print("Access denied")
            }
        })
    }


    // MARK: - Private

    func loadAllPhotos() {
        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: true)
        ]

        let results = PHAsset.fetchAssets(with: .image, options: options)

        var reusltAssets: [PHAsset] = []
        results.enumerateObjects { (object, _, _) in
            reusltAssets.append(object)
        }

        assets = reusltAssets
    }

    func classifyAllPhotosWithVision() {
        for asset in assets {
            cachingImageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: nil, resultHandler: { (initialResult, _) in
                if let image = initialResult {
                    self.classificationService.classify(image)
                }
            })
        }
    }

    func classifyAllPhotosWithCoreMLOnly() {
        let model = Nudity()
        for asset in assets {
            cachingImageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: nil, resultHandler: { (image, _) in
                guard let buffer = image?.gar_pixelBuffer() else {
                    fatalError("Scaling or converting to pixel buffer failed!")
                }

                guard let result = try? model.prediction(data: buffer) else {
                    fatalError("Prediction failed!")
                }

                let confidence = result.prob["\(result.classLabel)"]! * 100.0
                let converted = String(format: "%.2f", confidence)
            })
        }
    }
}

extension ViewController: ClassificationServiceDelegate {

    func classificationService(_ service: ClassificationService, didStartClassifying image: UIImage) {
        print("started...")
    }

    func classificationService(_ service: ClassificationService, didFailedClassifying error: Error?) {
        print("failed: \(error)")
    }

    func classificationService(_ service: ClassificationService, didFinishClassifying result: ClassificationResult?) {
        print("result: \(result)")
    }
}

