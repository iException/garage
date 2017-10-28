//
//  LockSplashViewController.swift
//  Garage
//
//  Created by Yiming Tang on 10/28/17.
//  Copyright © 2017 Baixing. All rights reserved.
//

import UIKit
import VENTouchLock

class LockSplashViewController: VENTouchLockSplashViewController {

    // MARK: - Properties

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = #imageLiteral(resourceName: "i-love-study")
        return imageView
    }()


    // MARK: - Initialzation

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setIsSnapshot(true)
        didFinishWithSuccess = { [weak self] (success: Bool, unlockType: VENTouchLockSplashViewControllerUnlockType) -> () in
            if success {
                self?.touchLock.backgroundLockVisible = false
                switch unlockType {
                case .touchID:
                    print("Unlocked with touch id")
                case .passcode:
                    print("Unlocked with passcode")
                case .none:
                    print("None passcode")
                }
            } else {
                let alert = UIAlertController(title: "Limit Exceeded", message: "You have exceeded the maximum number of passcode attempts", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor .constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(authenticate(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 4
        view.addGestureRecognizer(tapGestureRecognizer)
    }


    // MARK: - Actions

    @objc func authenticate(_ sender: UITapGestureRecognizer?) {
        if VENTouchLock.canUseTouchID() {
            showTouchID()
        } else {
            showPasscode(animated: true)
        }
    }
}
