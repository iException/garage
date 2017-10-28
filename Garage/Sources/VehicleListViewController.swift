//
//  VehicleListViewController.swift
//  Garage
//
//  Created by Xiang Li on 28/10/2017.
//  Copyright © 2017 Baixing. All rights reserved.


import UIKit
import RealmSwift
import SKPhotoBrowser
import Photos

class VehicleListViewController: UIViewController {
    
    private static let collectionViewInset: CGFloat = 5.0
    private static let numberOfColumns = 2
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionViewInset = VehicleListViewController.collectionViewInset
        layout.minimumInteritemSpacing = collectionViewInset
        layout.minimumLineSpacing = collectionViewInset
        layout.sectionInset = UIEdgeInsetsMake(collectionViewInset, collectionViewInset, collectionViewInset, collectionViewInset)
        var collectionView = UICollectionView(frame: CGRect(), collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(VehicleCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: VehicleCollectionViewCell.self))
        return collectionView
    }()
    
    lazy var realm: Realm = {
        return try! Realm()
    }()
    
    var vehicles: [VehicleViewModel]?
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        forgeData()
//        removeAllVehicle()
        setUpViews()
        setUpNavigationItems()
        configurePhotoBrowserOptions()
        reload()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.collectionView.frame = view.bounds
    }
    
    // MARK: - Private -
    
    private func setUpNavigationItems() {
        let buttonItem = UIBarButtonItem(title: "scan", style: .plain, target: self, action: #selector(scanButtonPressed(_:)))
        self.navigationItem.rightBarButtonItems = [ buttonItem ]
    }
    
    private func reload() {
        loadVehicle()
        reloadCollectionView()
    }
    
    // MARK: - Event Handler
    
    @objc private func scanButtonPressed(_ sender : Any) {
        let viewController = ViewController()
        viewController.delegate = self
        self.present(viewController, animated: true, completion: nil)
    }
    
    // MARK: - Realm
    
    private func forgeData() {
        for index in 0...5 {
            let imageName = "image\(index)"
            let image = UIImage(named:imageName)!
            let aVehicle = Vehicle(image: image)
            saveVehicle(vehicle: aVehicle, realm: realm)
            printVehicleCount(realm)
        }
    }
    
    private func printVehicleCount(_ realm: Realm) {
        print("Vehicle count is \(realm.objects(Vehicle.self).count)")
    }
    
    private func saveVehicle(vehicle: Vehicle, realm: Realm) {
        realm.beginWrite()
        realm.add(vehicle)
        try! realm.commitWrite()
    }
    
    private func deleteVehicle(vehicle: Vehicle, realm: Realm) {
        try! realm.write {
            realm.delete(vehicle)
        }
    }
    
    private func loadVehicle() {
        self.vehicles = realm.objects(Vehicle.self).map { (vehicle) -> VehicleViewModel in
            guard let image = vehicle.image else { return VehicleViewModel(image: UIImage(), model: vehicle) }
            let viewModel = VehicleViewModel(image: image, model: vehicle)
            return viewModel
        }
    }
    
    private func removeAllVehicle() {
        try! realm.write {
            realm.deleteAll()
        }
    }
    
    // MARK: - Photo Browser
    
    private func configurePhotoBrowserOptions() {
        SKPhotoBrowserOptions.displayStatusbar = true
        SKPhotoBrowserOptions.displayDeleteButton = true
        SKPhotoBrowserOptions.enableSingleTapDismiss = true
    }
    
    // MARK: - CollectionView
    
    private func setUpViews() {
        view.addSubview(collectionView)
    }
    
    private func reloadCollectionView() {
        collectionView.reloadData()
    }
    
    // MARK: - Wrapper
    
    private func viewModelAtIndex(index: Int) -> VehicleViewModel? {
        guard let vehicles = vehicles else { return nil }
        return vehicles[safe: index]
    }
    
    private func imageAtIndex(index: Int) -> UIImage? {
        guard let vehicle = viewModelAtIndex(index: index) else { return nil }
        return vehicle.image
    }
    
}

extension VehicleListViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let vehicles = vehicles else { return 0 }
        return vehicles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: VehicleCollectionViewCell.self), for: indexPath) as? VehicleCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        cell.imageView.image = imageAtIndex(index: indexPath.item)
        return cell
    }
    
}

extension VehicleListViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfColumns = Double(VehicleListViewController.numberOfColumns)
        let collectionViewWidth = Double(collectionView.frame.size.width)
        let collectionViewInset = Double(VehicleListViewController.collectionViewInset)
        let width = (collectionViewWidth - (numberOfColumns + 1) * collectionViewInset) / numberOfColumns
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? VehicleCollectionViewCell else {
            return
        }
        
        guard let image = imageAtIndex(index: indexPath.item) else {
            return
        }
        
        showPhotoBrowser(image: image, photos: vehicles!, sourceView: cell, index: indexPath.item)
    }
    
    private func showPhotoBrowser(image: UIImage, photos: [SKPhotoProtocol], sourceView: UIView, index: Int) {
        let browser = SKPhotoBrowser(originImage: image, photos: photos, animatedFromView: sourceView)
        browser.initializePageIndex(index)
        browser.delegate = self
        browser.showDeleteButton(bool: true)
        present(browser, animated: true, completion: {})
    }
}

extension VehicleListViewController: SKPhotoBrowserDelegate {
    
    func removePhoto(_ browser: SKPhotoBrowser, index: Int, reload: @escaping (() -> Void)) {
        guard let vehicle = viewModelAtIndex(index: index) else { return }
        deleteVehicle(vehicle: vehicle.model, realm: realm)
        self.reload()
        reload()
    }
    
    func viewForPhoto(_ browser: SKPhotoBrowser, index: Int) -> UIView? {
        return collectionView.cellForItem(at: IndexPath(item: index, section: 0))
    }
    
}

extension VehicleListViewController: ViewControllerDelegate {
    
    func viewControllerFinishClassifying(_ viewController: ViewController, assets: [PHAsset]) {
        viewController.dismiss(animated: true, completion: nil)
        saveAssetsToDatabase(assets)
        deleteAssets(assets)
    }
}

extension VehicleListViewController {
    
    private func saveAssetsToDatabase(_ assets: [PHAsset]) {
        let dispatchGroup = DispatchGroup()

        for (index, asset) in assets.enumerated() {
            let size = CGSize(width: 500, height: 500)
            dispatchGroup.enter()
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options, resultHandler: { (image, info) in
                defer {
                    dispatchGroup.leave()
                }
                guard let image = image else {
                    return
                }
                
                let vehicle = Vehicle(image: image)
                if vehicle.imageData != nil {
                    self.saveVehicle(vehicle: vehicle, realm: self.realm)
                }
            })
        }
        
        dispatchGroup.notify(queue: .main) {
            self.reload()
        }
    }
    
    private func deleteAssets(_ assets: [PHAsset]) {
        // TODO:
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(NSArray(array: assets))
        }) { (result, error) in
        }
    }
}
