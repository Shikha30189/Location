//
//  LocationService.swift
//  Location
//
//  Created by shikha on 26/07/21.
//


import Foundation
import UIKit
import CoreLocation
import UserNotifications
import Firebase

enum Result<T> {
  case success(T)
  case failure(Error)
}


final class LocationService: NSObject {
    let manager: CLLocationManager
    var myLocation: CLLocation?
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let localFence = "LocalFence"
    var onLocationFetched: ((CLLocation)->Void)? = nil
   


    init(manager: CLLocationManager = .init()) {
        self.manager = manager
        
        super.init()
        manager.delegate = self
        registerNotifications()
      //  ref1 = Database.database().reference()

//        for region in manager.monitoredRegions {
//            manager.stopMonitoring(for: region)
//        }
    }

    var newLocation: ((Result<CLLocation>) -> Void)?
    var didChangeStatus: ((Bool) -> Void)?

    var status: CLAuthorizationStatus {
        return self.manager.authorizationStatus
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
    

    func requestLocationAuthorization() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.requestWhenInUseAuthorization()
//        manager.stopMonitoringSignificantLocationChanges()
        if CLLocationManager.locationServicesEnabled() {
            manager.startUpdatingLocation()
            //locationManager.startUpdatingHeading()
        }
    }
    
    func requestLocation() {
        manager.startUpdatingLocation()
    }

    func requestLocationAlwaysAuthorization() {
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
    }

    func getLocation() {
        manager.requestLocation()
    }

    deinit {
        manager.stopUpdatingLocation()
    }
    
    
    func createRegion(coordinate:CLLocationCoordinate2D, radius: Double = 100.0, regionName: String = "LocalFence") {

        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            //let regionName = "FenceRegion"
            //let coordinate = CLLocationCoordinate2DMake((location!.coordinate.latitude), (location!.coordinate.longitude))
            //let coords = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let region = CLCircularRegion(center: coordinate, radius: radius, identifier: regionName)
            region.notifyOnEntry = true
            region.notifyOnExit  = true
           // fetchData(region: region)
            addViewOnWindow(text: "region created")
            scheduleLocalNotification(alert: "\nRegion Created for identifier ===\(regionName) === regionRadius ===== \(radius) \(coordinate)", identifier: "FenceCreate", imageURLS: nil)
            manager.startMonitoring(for: region)
            if regionName == localFence {
                /// fetch regions from server
                fetchServerRegionToBeMonitored(region: region)
            }
            
        }
    }
    
    func fetchServerRegionToBeMonitored(region: CLCircularRegion) {
        AppDelegate.ref.child("Regions").observeSingleEvent(of: .value) { snapshot in
            print("\(String(describing:  snapshot.value))")
            if let tempDic : Dictionary = snapshot.value as? Dictionary<String,Any> {
                print(tempDic)
                for key in tempDic.keys {
                    let selectedDic = tempDic[key] as! Dictionary<String,Any>
                    let latittude = selectedDic["Latitude"] as! Double
                    let longitude = selectedDic["Longitude"] as! Double
                    let coords = CLLocationCoordinate2D(latitude: latittude, longitude: longitude)

                    if region.contains(coords) {
                        //
                       let regionID = selectedDic["rid"] as? String
                        //isRegion = true
                        //break
                        self.createRegion(coordinate: coords, radius: 25.0, regionName: regionID ?? "abc")
                    }
                }
            }
        }
    }
    
    
    func fetchDataInRegion(regionIdentifier: String) {
        AppDelegate.ref.child("Posts").queryOrdered(byChild: "regionid").queryEqual(toValue : regionIdentifier).observeSingleEvent(of: .value) { snapshot in
            print("\(String(describing:  snapshot.value))")
            var imgURLS = [String]()
            if let tempDic : Dictionary = snapshot.value as? Dictionary<String,Any> {
                for key in tempDic.keys {
                    let selectedDic = tempDic[key] as! Dictionary<String,Any>
                    imgURLS.append(selectedDic["myImageURL"] as! String)
                }
            }
           // print("POST DATA")
            
            self.scheduleLocalNotification(alert: "\(String(describing:  snapshot.value))", identifier: "PHOTODATA", imageURLS: imgURLS)
            
        } withCancel: { error in
            print("POST ERROR")
            self.scheduleLocalNotification(alert: "ERROR", identifier: "PHOTODATA", imageURLS: nil)
            
        }
        
    }
}



 extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        newLocation?(.failure(error))
        //manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            onLocationFetched?(location)
            myLocation = location
           // scheduleLocalNotification(alert: "location update")
            if self.manager.monitoredRegions.count == 0 {
                if let loc = myLocation {
                    createRegion(coordinate: loc.coordinate)
                }
            }
         
        }else {
            print("\nCannot fetch user location")
        }
        if let location = locations.sorted(by: {$0.timestamp > $1.timestamp}).first {
            newLocation?(.success(location))
        }
      
       // manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined, .restricted, .denied:
            didChangeStatus?(false)
        default:
            didChangeStatus?(true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region.identifier != localFence {
            /// fetch images data
            
            UIApplication.shared.beginBackgroundTask(withName: "Fetch Data", expirationHandler: {
                UIApplication.shared.endBackgroundTask(AppDelegate.backgroundDataTaskId)
                AppDelegate.backgroundDataTaskId = .invalid
            })
        
            fetchDataInRegion(regionIdentifier: region.identifier)
            UIApplication.shared.endBackgroundTask(AppDelegate.backgroundDataTaskId)
            AppDelegate.backgroundDataTaskId = .invalid
            
            
        } else {
            if let cordinates = myLocation {
               // addViewOnWindow(text: "Enter region")

                scheduleLocalNotification(alert: "didEnterRegion ====\(region.identifier)===Lat=====\(cordinates.coordinate.latitude)====Long=====\(cordinates.coordinate.longitude)", imageURLS: nil)
            } else {
                scheduleLocalNotification(alert: "didEnterRegion ====\(region.identifier)", imageURLS: nil)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
            
            if region.identifier == localFence {
                manager.startUpdatingLocation()
                var isRegionCreated = true
                onLocationFetched = { location in
                    if let loc = self.myLocation {
                        if isRegionCreated {
                            DispatchQueue.global().async {
                                
                                // Request the task assertion and save the ID.
                                AppDelegate.backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "Fetch Regions", expirationHandler: {
                                    UIApplication.shared.endBackgroundTask(AppDelegate.backgroundTaskId)
                                    AppDelegate.backgroundTaskId = .invalid
                                })
                                
                                for region in manager.monitoredRegions {
                                    manager.stopMonitoring(for: region)
                                }
                                self.createRegion(coordinate: loc.coordinate)
                                    UIApplication.shared.endBackgroundTask(AppDelegate.backgroundTaskId)
                                    AppDelegate.backgroundTaskId = .invalid
                                isRegionCreated = false
                            }
                        }
                    }
                    
                }
                
                if let cordinates = myLocation {
                    addViewOnWindow(text: "Exit region")
                    scheduleLocalNotification(alert: "ndidExitRegion ====\(region.identifier) ===Lat=====\(cordinates.coordinate.latitude)====Long=====\(cordinates.coordinate.longitude)", imageURLS: nil)
                    
                } else {
                    scheduleLocalNotification(alert: "ndidExitRegion ====\(region.identifier)", imageURLS: nil)
                }

            }
        }
    
/*
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        
        if region.identifier == localFence {
            var isCreateRegion = true
            manager.startUpdatingLocation()
            if let cordinates = myLocation {
                addViewOnWindow(text: "Exit region")
                scheduleLocalNotification(alert: "ndidExitRegion ====\(region.identifier) ===Lat=====\(cordinates.coordinate.latitude)====Long=====\(cordinates.coordinate.longitude)", imageURLS: nil)
                
            } else {
                scheduleLocalNotification(alert: "ndidExitRegion ====\(region.identifier)", imageURLS: nil)
                
            }
            
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        if let loc = self.myLocation {
                            for region in manager.monitoredRegions {
                                manager.stopMonitoring(for: region)
                            }
                            self.createRegion(coordinate: loc.coordinate)
                        }
                    }
            
//            onLocationFetched = { location in
//                if isCreateRegion {
//                    if let loc = self.myLocation {
//                        for region in manager.monitoredRegions {
//                            manager.stopMonitoring(for: region)
//                        }
//                        self.createRegion(coordinate: loc.coordinate)
//                        isCreateRegion = false
//                    }
//                }
//
//            }

        } else {
            
        }
        
    }
 */
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        //locationTextView.text += "\nRegion Error====\(error.localizedDescription)"
        scheduleLocalNotification(alert: "failRegionMonitoring ====\(error.localizedDescription)", imageURLS: nil)
    }
    
}


extension LocationService: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // get the notification identifier to respond accordingly
        if let imageURLS = response.notification.request.content.userInfo["imgurls"] as? [String] {
//            var backButtonImage = UIImage(named: "Capture")
//            //      var backButtonImage = UIImage(named: "back-button-image")
//            backButtonImage = backButtonImage?.stretchableImage(withLeftCapWidth: 15, topCapHeight: 30)
//            UIBarButtonItem.appearance().setBackButtonBackgroundImage(backButtonImage, for: .normal, barMetrics: .default)
            
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let homeController: GalleryViewController = mainStoryboard.instantiateViewController(withIdentifier: "GalleryViewController") as! GalleryViewController
            homeController.items = imageURLS
            
            guard let tabBarVC = UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.rootViewController as? UITabBarController else { return }
                if let currentNavController = tabBarVC.selectedViewController as? UINavigationController {
                    currentNavController.pushViewController(homeController, animated: true)
            }
        }

    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                  willPresent notification: UNNotification,
                                  withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
          let userInfo = notification.request.content.userInfo
          print(userInfo) // the payload that is attached to the push notification
          // you can customize the notification presentation options. Below code will show notification banner as well as play a sound. If you want to add a badge too, add .badge in the array.
          completionHandler([.alert,.sound])
      }
 
    
   
    func addViewOnWindow(text: String) {
        let window = UIApplication.shared.keyWindow!
        let alert = UIAlertController(title: "Geofence", message:text, preferredStyle: UIAlertController.Style.alert)
        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        // show the alert
        window.rootViewController?.present(alert, animated: true, completion: nil)
    }
    

    func scheduleLocalNotification(alert:String, identifier: String = "fence", imageURLS: [String]?) {
            let content = UNMutableNotificationContent()
            let requestIdentifier = identifier
            content.badge = 0
            content.title = "Fence Region"
            content.body = alert
            content.sound = UNNotificationSound.default
        if let _ = imageURLS {
            content.userInfo = ["imgurls":imageURLS!]
        }
            let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 1.0, repeats: false)
            let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { (error:Error?) in
                print("Notification Register Success")
            }
        }
}

