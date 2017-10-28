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

    lazy var authButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Open", for: .normal)
        button.setTitleColor(#colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1), for: .normal)
        button.addTarget(self, action: #selector(authenticate(_:)), for: .touchUpInside)
        return button
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
        view.addSubview(authButton)

        NSLayoutConstraint.activate([
            authButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            authButton.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
        ])
    }


    // MARK: - Actions

    @objc func authenticate(_ sender: UIButton?) {
        if VENTouchLock.canUseTouchID() {
            showTouchID()
        } else {
            showPasscode(animated: true)
        }
    }
}
