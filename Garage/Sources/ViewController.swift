//
//  ViewController.swift
//  Garage
//
//  Created by Yiming Tang on 10/27/17.
//  Copyright © 2017 Baixing. All rights reserved.
//

import UIKit
import Photos
import VENTouchLock

final class ViewController: UIViewController {

    // MARK: - Properties
    let targetSize = CGSize(width: 224, height: 224)
    let cachingImageManager = PHCachingImageManager()
    var currentIndex: Int = NSNotFound
    var nsfwAssets: [PHAsset] = []
    var assets: [PHAsset] = [] {
        willSet {
            cachingImageManager.stopCachingImagesForAllAssets()
        }

        didSet {
            cachingImageManager.startCachingImages(for: self.assets, targetSize: targetSize, contentMode: .aspectFit, options: nil)
        }
    }

    private let scanButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Scan", for: .normal)
        button.setTitleColor(#colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1), for: .normal)
        return button
    }()

    private let passcodeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Set Passcode", for: .normal)
        button.setTitleColor(#colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1), for: .normal)
        return button
    }()

    lazy var classificationService: ClassificationService = {
        let service = ClassificationService()
        service.delegate = self
        return service
    }()


    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        view.addSubview(scanButton)
        view.addSubview(passcodeButton)

        NSLayoutConstraint.activate([
            scanButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            scanButton.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            passcodeButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            passcodeButton.topAnchor.constraint(equalTo: scanButton.bottomAnchor, constant: 10),
        ])

        scanButton.addTarget(self, action: #selector(scan(_:)), for: .touchUpInside)
        passcodeButton.addTarget(self, action: #selector(setPasscode(_:)), for: .touchUpInside)
    }


    // MARK: - Actions

    @objc func scan(_ sender: UIButton?) {
        PHPhotoLibrary.requestAuthorization({ (status) in
            if (status == .authorized) {
                DispatchQueue.main.async {
                    self.loadAllPhotos()
                    self.classifyAllPhotos()
                }
            } else {
                print("Access denied")
            }
        })
    }

    @objc func setPasscode(_ sender: UIButton?) {
        if (VENTouchLock.sharedInstance().isPasscodeSet()) {
            print("Passcode already exists")
        } else {
            let viewController = UINavigationController(rootViewController: VENTouchLockCreatePasscodeViewController())
            present(viewController, animated: true, completion: nil)
            VENTouchLock.sharedInstance().backgroundLockVisible = false
        }
    }


    // MARK: - Private

    private func loadAllPhotos() {
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

    private func classifyAllPhotos() {
        currentIndex = -1
        nsfwAssets = []
        classifyNextPhoto()
    }

    private func classifyNextPhoto() {
        currentIndex += 1
        guard currentIndex < assets.count else {
            finishClassifyingAllPhotos()
            return
        }

        let asset = assets[currentIndex]
        cachingImageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: nil, resultHandler: { [weak self] (initialResult, _) in
            if let image = initialResult {
                self?.classificationService.classify(image, for: asset)
            } else {
                self?.classifyNextPhoto()
            }
        })
    }

    private func finishClassifyingAllPhotos() {
        // TODO: Handle nsfwAssets
        print("finishClassifyingAllPhotos")
    }
}

extension ViewController: ClassificationServiceDelegate {
    func classificationService(_ service: ClassificationService, didFinishClassifying results: [ClassificationResult]?, with identifier: Any?) {
        print("======== FinishClassifying ========\nIndex: \(currentIndex)")

        DispatchQueue.main.async {
            results?.forEach({ (result) in
                print(result)
            })

            print("\n")

            if results?.first?.label == .nsfw {
                if let asset = identifier {
                    self.nsfwAssets.append(asset as! PHAsset)
                }
            }

            self.classifyNextPhoto()
        }
    }

    func classificationService(_ service: ClassificationService, didStartClassifying image: UIImage, with identifier: Any?) {
        print("======== Start Classifying ========\nIndex: \(currentIndex)")
    }

    func classificationService(_ service: ClassificationService, didFailedClassifying error: Error?, with identifier: Any?) {
        print("======== Failed Classifying ========\nIndex: \(currentIndex)\nError: \(error?.localizedDescription ?? "unkown eror")\n")
    }
}

