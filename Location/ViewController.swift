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

var vSpinner : UIView?

extension UIViewController {
    func showSpinner(onView : UIView) {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(style: .large)
        ai.startAnimating()
        ai.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
        
        vSpinner = spinnerView
    }
    
    func removeSpinner() {
        DispatchQueue.main.async {
            vSpinner?.removeFromSuperview()
            vSpinner = nil
        }
    }
}
