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
    
    @IBOutlet weak var locationTextView: UITextView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var textFieldRadius: UITextField!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        locationServiceObject = appDelegate.locationServiceObject
        
        locationServiceObject.didChangeStatus = { status in
            switch status {
            case .authorizedAlways:
                self.locationServiceObject.getLocation()
                let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let homeController = mainStoryboard.instantiateViewController(withIdentifier: "HomeViewController")
                appDelegate.window!.rootViewController = homeController
                
            case .authorizedWhenInUse:
                self.locationServiceObject.requestLocationAlwaysAuthorization()
                
            case .denied:
                self.locationServiceObject.requestLocationAuthorization()
                
            case .notDetermined:
                self.locationServiceObject.requestLocationAuthorization()
                
            case .restricted:
                self.locationServiceObject.requestLocationAuthorization()
                
            @unknown default:
                self.locationServiceObject.requestLocationAuthorization()
            }
        }
        
    }
}
