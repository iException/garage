//
//  ViewController.swift
//  Garage
//
//  Created by Yiming Tang on 10/27/17.
//  Copyright © 2017 Baixing. All rights reserved.
//

import UIKit
import RealmSwift
import SKPhotoBrowser

class ViewController: UIViewController {
    
    private static let collectionViewInset: CGFloat = 5.0
    private static let numberOfColumns = 2
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionViewInset = ViewController.collectionViewInset
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
        
        forgeData()
        setUpViews()
        configurePhotoBrowserOptions()
        loadVehicle()
        reloadCollectionView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.collectionView.frame = view.bounds
    }
    
    // MARK: - Private -
    
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
            let viewModel = VehicleViewModel(image: vehicle.image!, model: vehicle)
            return viewModel
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

extension ViewController: UICollectionViewDataSource {
    
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

extension ViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfColumns = Double(ViewController.numberOfColumns)
        let collectionViewWidth = Double(collectionView.frame.size.width)
        let collectionViewInset = Double(ViewController.collectionViewInset)
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

extension ViewController: SKPhotoBrowserDelegate {
    
    func removePhoto(_ browser: SKPhotoBrowser, index: Int, reload: @escaping (() -> Void)) {
        guard let vehicle = viewModelAtIndex(index: index) else { return }
        deleteVehicle(vehicle: vehicle.model, realm: realm)
        loadVehicle()
        reloadCollectionView()
        reload()
    }
    
    func viewForPhoto(_ browser: SKPhotoBrowser, index: Int) -> UIView? {
        return collectionView.cellForItem(at: IndexPath(item: index, section: 0))
    }
    
}

