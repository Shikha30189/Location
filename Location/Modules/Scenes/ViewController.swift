//
//  ViewController.swift
//  Location
//
//  Created by shikha on 09/07/21.
//

import UIKit
import CoreLocation


class ViewController: UIViewController, UNUserNotificationCenterDelegate {
    var locationServiceObject: LocationService!
    var isChangingAuthorisationStatus = false
    
    @IBOutlet weak var locationTextView: UITextView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var textFieldRadius: UITextField!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        locationServiceObject = appDelegate.locationServiceObject
        
        locationServiceObject.didChangeStatus = { [weak self] status in
            
            guard let strongSelf = self else {
                return
            }
            
            switch status {
            case .authorizedAlways:
                if  strongSelf.isChangingAuthorisationStatus && UIApplication.shared.applicationState != .background {
                    strongSelf.locationServiceObject.onAppForeground()
                }
                let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let homeController = mainStoryboard.instantiateViewController(withIdentifier: "HomeViewController")
                appDelegate.window!.rootViewController = homeController
                
            case .authorizedWhenInUse:
                strongSelf.isChangingAuthorisationStatus = true
                strongSelf.locationServiceObject.requestLocationAlwaysAuthorization()
                
            case .denied:
                strongSelf.isChangingAuthorisationStatus = true
                strongSelf.locationServiceObject.requestLocationAuthorization()
                
            case .notDetermined:
                strongSelf.isChangingAuthorisationStatus = true
                strongSelf.locationServiceObject.requestLocationAuthorization()
                
            case .restricted:
                strongSelf.isChangingAuthorisationStatus = true
                strongSelf.locationServiceObject.requestLocationAuthorization()
                
            @unknown default:
                strongSelf.isChangingAuthorisationStatus = true
                strongSelf.locationServiceObject.requestLocationAuthorization()
            }
        }
        
    }
}
