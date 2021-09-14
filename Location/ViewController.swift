//
//  ViewController.swift
//  Location
//
//  Created by shikha on 09/07/21.
//

import UIKit
import CoreLocation


class ViewController: UIViewController, UNUserNotificationCenterDelegate {
    var locationManager = CLLocationManager()
    var myLocation: CLLocation?
//    var onLocationFetched: ((CLLocation)->Void)? = nil
    var locationServiceObject: LocationService!
    
    @IBOutlet weak var locationTextView: UITextView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var textFieldRadius: UITextField!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        locationServiceObject = appDelegate.locationServiceObject
       // checkLocationServices()
        locationServiceObject.didChangeStatus = { status in
            if status {
                if self.locationServiceObject.status == .authorizedWhenInUse {
                   self.locationServiceObject.requestLocationAlwaysAuthorization()

                } else {
                    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let homeController = mainStoryboard.instantiateViewController(withIdentifier: "HomeViewController")
                        appDelegate.window!.rootViewController = homeController
                }
                
            } else {
                if self.locationServiceObject.status == .notDetermined || self.locationServiceObject.status == .restricted || self.locationServiceObject.status == .denied {
                    self.locationServiceObject.requestLocationAuthorization()
                }
                else if self.locationServiceObject.status == .authorizedWhenInUse {
                    //self.locationServiceObject.requestLocation()
//                    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
//                    let homeController = mainStoryboard.instantiateViewController(withIdentifier: "HomeViewController")
//                        appDelegate.window!.rootViewController = homeController

                    self.locationServiceObject.requestLocationAlwaysAuthorization()
//                    locationManager.requestAlwaysAuthorization()
//                    locationManager.startUpdatingLocation()

                } else if self.locationServiceObject.status == .authorizedAlways {
                   // self.locationServiceObject.requestLocationAlwaysAuthorization()

                    self.locationServiceObject.requestLocation()
                    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let homeController = mainStoryboard.instantiateViewController(withIdentifier: "HomeViewController")
                        appDelegate.window!.rootViewController = homeController
                }
            }
        }
//        registerNotifications()
//        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
               
    }
    
//    func checkLocationServices(){
//        if CLLocationManager.locationServicesEnabled(){
//            checkLocationAuthorization()
//        } else {
//            // alert user must turn on
//        }
//    }
//
  

 /*
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        

        
        
//        var region = "No region"
//        if locationManager.monitoredRegions.count > 0 {
//            region = locationManager.monitoredRegions.first?.identifier ?? "Blank region"
//        }
        
//        let appDelegate = UIApplication.shared.delegate as! AppDelegate
//        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
//        let homeController = mainStoryboard.instantiateViewController(withIdentifier: "HomeViewController")
//            appDelegate.window!.rootViewController = homeController
        
//        let alert = UIAlertView()
//        alert.title = "Fenced Region"
//        alert.message = region
//        alert.addButton(withTitle: "ok")
//        alert.show()
//        let alert = UIAlertController(title: "Fenced Region", message: region, preferredStyle: UIAlertController.Style.alert)
//        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
//        self.present(alert, animated: true, completion: nil)
    }
    
    func registerNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.badge,.sound]) { (granted:Bool, error:Error?) in
            if error != nil { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        UNUserNotificationCenter.current().delegate = self
    }
    
    func scheduleLocalNotification(alert:String) {
            let content = UNMutableNotificationContent()
            let requestIdentifier = UUID.init().uuidString
            
            content.badge = 0
            content.title = "Fence Region"
            content.body = alert
            content.sound = UNNotificationSound.default
            
            let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 1.0, repeats: false)
            let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { (error:Error?) in
                print("Notification Register Success")
            }
        }
        
    

    @IBAction func geoFenceClicked(_ sender: Any) {
        locationManager.requestLocation()

        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        if let loc = myLocation {
            createRegion(location: myLocation)
        } else {
            let alert = UIAlertView()
            alert.title = "Location Error"
            alert.message = "Fail to fetch location"
            alert.addButton(withTitle: "ok")
            alert.show()
        }

//        locationManager.requestLocation()
//        onLocationFetched = { location in
//            self.createRegion(location: location)
//        }
    }
    
    @IBAction func locationClicked(_ sender: Any) {
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        else if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()

        }
        else if CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
}


extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        } else if status ==  .authorizedWhenInUse {
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        } else  {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            //onLocationFetched?(location)
            myLocation = location
            
        }else {
            locationTextView.text  +=  "\nCannot fetch user location"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let cordinates = myLocation {
            locationTextView.text  +=  "\ndidEnterRegion ====\(region.identifier)===== Lat=====\(cordinates.coordinate.latitude)====Long=====\(cordinates.coordinate.longitude)"
            scheduleLocalNotification(alert: "didEnterRegion ====\(region.identifier)===Lat=====\(cordinates.coordinate.latitude)====Long=====\(cordinates.coordinate.longitude)")
        } else {
            locationTextView.text  +=  "\ndidEnterRegion ====\(region.identifier)===== "
            scheduleLocalNotification(alert: "didEnterRegion ====\(region.identifier)")
        }

    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let cordinates = myLocation {
            locationTextView.text  += "\ndidExitRegion ====\(region.identifier)========Lat=====\(cordinates.coordinate.latitude)====Long=====\(cordinates.coordinate.longitude)"
            
            scheduleLocalNotification(alert: "ndidExitRegion ====\(region.identifier) ===Lat=====\(cordinates.coordinate.latitude)====Long=====\(cordinates.coordinate.longitude)")
        } else {
            locationTextView.text  += "\ndidExitRegion ====\(region.identifier)"
            scheduleLocalNotification(alert: "ndidExitRegion ====\(region.identifier)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        locationTextView.text += "\nRegion Error====\(error.localizedDescription)"

    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationTextView.text += "\nLocation Error====\(error.localizedDescription)"
    }
    
    func createRegion(location:CLLocation?) {
        
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self), let regionName = textField.text {
            let coordinate = CLLocationCoordinate2DMake((location!.coordinate.latitude), (location!.coordinate.longitude))
            let regionRadius = Double(textFieldRadius.text ?? "50") ?? 50.0
            let coords = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let region = CLCircularRegion(center: coords, radius: regionRadius, identifier: regionName)
            region.notifyOnEntry = true
            region.notifyOnExit  = true
            locationTextView.text += "\nRegion Created for identifier ===\(regionName) === regionRadius ===== \(regionRadius) \(location!.coordinate) with \(location!.horizontalAccuracy)"
            self.locationManager.startMonitoring(for: region)
        }
    }
     */
    
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
