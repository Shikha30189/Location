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
import FCAlertView

enum Result<T> {
  case success(T)
  case failure(Error)
}

typealias LocationResult = (Result<CLLocation>) -> Void
typealias CallBack = () -> Void


final class LocationService: NSObject {
    var manager: CLLocationManager!
    var myLocation: CLLocation?
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let localFence = "LocalFence"
    var previousLocation: CLLocation?
    var currentLocation: CLLocation?
    var filteredRegions = [[String: Any]]()
    var lastSavedHstryRegionID: String?
    var  alert:FCAlertView?


    init(manager: CLLocationManager = .init()) {
        super.init()
        manager.allowsBackgroundLocationUpdates = true
        manager.activityType = .automotiveNavigation
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 2
        self.manager = manager
        self.manager.delegate = self
        self.manager.startUpdatingLocation()
        registerNotifications()
    }

    var newLocation: LocationResult?
    var didChangeStatus: ((CLAuthorizationStatus) -> Void)?

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
        manager.requestWhenInUseAuthorization()
    }

    func requestLocationAlwaysAuthorization() {
        manager.requestAlwaysAuthorization()
    }

    func getLocation(_ result: LocationResult? = nil) {
        newLocation = result
        manager.requestLocation()
    }
    
    func initialiseAllRegions(with userLocation: CLLocationCoordinate2D) {
            AppDelegate.backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "com.HSTRY.FetchRegions", expirationHandler: {
                UIApplication.shared.endBackgroundTask(AppDelegate.backgroundTaskId)
                AppDelegate.backgroundTaskId = .invalid
            })
            
            for region in manager.monitoredRegions {
                manager.stopMonitoring(for: region)
            }
            
            createRegion(coordinate: userLocation) {
                UIApplication.shared.endBackgroundTask(AppDelegate.backgroundTaskId)
                AppDelegate.backgroundTaskId = .invalid
            }
    }
    
    
    func createRegion(coordinate: CLLocationCoordinate2D, radius: Double = UserDefaults.standard.double(forKey: AppDelegate.outerRadiusKey), regionName: String = "LocalFence", completion: CallBack? = nil ) {

        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            let region = CLCircularRegion(center: coordinate, radius: radius, identifier: regionName)
            region.notifyOnEntry = true
            region.notifyOnExit  = true
            manager.startMonitoring(for: region)
            if regionName == localFence {
                fetchServerRegionToBeMonitored(region: region, completion: completion)
            }else {
                completion?()
            }
            
        }else {
            completion?()
        }
    }
    
    func fetchServerRegionToBeMonitored(region: CLCircularRegion, completion: CallBack? = nil) {
        AppDelegate.ref.child("Regions").observeSingleEvent(of: .value) { snapshot in
            
            if let tempDic : Dictionary = snapshot.value as? Dictionary<String,Any> {
                var hstryHotspotRegionList = [[String: Any]]()
                for key in tempDic.keys {
                    let selectedDic = tempDic[key] as! Dictionary<String,Any>
                    let latittude = selectedDic["Latitude"] as! Double
                    let longitude = selectedDic["Longitude"] as! Double
                    let coords = CLLocationCoordinate2D(latitude: latittude, longitude: longitude)
                    
                    if region.contains(coords) {
                        
                       let regionID = selectedDic["rid"] as? String
                        let innerRadius  = UserDefaults.standard.double(forKey: AppDelegate.innerRadiusKey)
                        self.createRegion(coordinate: coords, radius: innerRadius, regionName: regionID ?? "abc")
                        
                        
                        /// Check if user lcurrent location is in the HSTRY region, if so, trigger notification
                        if let currentLocation = self.myLocation {
                            let hstryHotspotRegion = CLCircularRegion(center: coords, radius: innerRadius, identifier: "hstryHotspotRegion")
                            if hstryHotspotRegion.contains(currentLocation.coordinate) {
                                hstryHotspotRegionList.append(selectedDic)
                            }
                        }
                        
                    }
                }
                if let selctedRgionID = self.minimumDistanceBetweenCoordinates(arrRegions: hstryHotspotRegionList,currentLocation: self.myLocation) {
                    self.fetchDataInRegion(regionIdentifier: selctedRgionID)
                }
            }
            
            completion?()
        }
    }
    

    func minimumDistanceBetweenCoordinates(arrRegions: [[String: Any]], currentLocation: CLLocation?) -> String? {
        var selectedDic:[String: Any]?
        if arrRegions.count == 0 {
            return nil
        } else if arrRegions.count == 1 {
            selectedDic = arrRegions.first
        } else {
            if let myLocation = currentLocation {
                var distanceArr = [Double]()
                for element in arrRegions {
                    let latittude = element["Latitude"] as! Double
                    let longitude = element["Longitude"] as! Double
                    let regionLocation = CLLocation(latitude: latittude, longitude: longitude)
                    distanceArr.append(myLocation.distance(from: regionLocation))
                }
                let minimumDistanc = distanceArr.min()
                selectedDic = arrRegions[distanceArr.firstIndex(of: minimumDistanc ?? 0.0) ?? 0]
            }
            
        }
        return (selectedDic != nil) ? selectedDic!["rid"] as? String: nil
    }

    
    func fetchDataInRegion(regionIdentifier: String, callback: ((Bool) -> Void)? = nil) {
        AppDelegate.ref.child("Posts").queryOrdered(byChild: "regionid").queryEqual(toValue : regionIdentifier).observeSingleEvent(of: .value) { snapshot in
            
            var imgURLS = [String]()
            if let tempDic : Dictionary = snapshot.value as? Dictionary<String,Any> {
                for key in tempDic.keys {
                    let selectedDic = tempDic[key] as! Dictionary<String,Any>
                    imgURLS.append(selectedDic["myImageURL"] as! String)
                }
            }
            self.scheduleLocalNotification(alert: "\(String(describing:  snapshot.value))", imageURLS: imgURLS)
            callback?(true)
            
        } withCancel: { error in
            print("POST ERROR")
            self.scheduleLocalNotification(alert: "ERROR", imageURLS: nil)
            callback?(false)
        }
        
    }
    
    func updateMonitoredRegions() {
        getLocation { [weak self] result in
            if case let .success(latestLocation) = result {
                self?.initialiseAllRegions(with: latestLocation.coordinate)
            }
        }
    }
}



 extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        newLocation?(.failure(error))
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
           // showForegroundDataAlert(imageUrls: [""])
            if previousLocation == nil, currentLocation == nil {
                previousLocation = location
                currentLocation = location
            }
            if checkDistanceBetweenCoordinates() {
                // create region of 40m, fetch data from server and find the nearest hstry spot
                previousLocation = location
                currentLocation = location
                regionHandlingInForeground()
                
            } else {
                // locally fetch the nearest hstry spot
                currentLocation = location
                checkContinuousRegionForLocationUpdate()
            }
            myLocation = location
            newLocation?(.success(location))
            newLocation = nil
        } else {
            print("\nCannot fetch user location")
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        didChangeStatus?(status)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region.identifier != localFence {
            
            AppDelegate.backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "com.HSTRY.FetchData", expirationHandler: {
                UIApplication.shared.endBackgroundTask(AppDelegate.backgroundDataTaskId)
                AppDelegate.backgroundDataTaskId = .invalid
            })
        
            fetchDataInRegion(regionIdentifier: region.identifier) { isData in
                UIApplication.shared.endBackgroundTask(AppDelegate.backgroundDataTaskId)
                AppDelegate.backgroundDataTaskId = .invalid
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
            if region.identifier == localFence {
                //scheduleLocalNotification(alert: "didExitRegion", imageURLS: nil)
                getLocation { [weak self] result in
                    if case let .success(latestLocation) = result {
                        self?.initialiseAllRegions(with: latestLocation.coordinate)
                    }
                }
                
            }
        }
    

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        scheduleLocalNotification(alert: "failRegionMonitoring ====\(error.localizedDescription)", imageURLS: nil)
    }
    
}


extension LocationService: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if let imageURLS = response.notification.request.content.userInfo["imgurls"] as? [String] {
                appDelegate.imageURLS = imageURLS
        }
    }
    
    func navigateGalleryScreen(imageURLS: [String]) {
        let controller =  UIApplication.getTopViewController()
        if controller is GalleryViewController {
            //reload data
            (controller as? GalleryViewController)?.items = imageURLS
            (controller as? GalleryViewController)?.refreshData()
            
        } else {
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
//          let userInfo = notification.request.content.userInfo
//          print(userInfo)
//          completionHandler([.alert,.sound])
      }
    

    func scheduleLocalNotification(alert:String, identifier: String = UUID().uuidString, imageURLS: [String]?) {
        if  UIApplication.shared.applicationState == .active {
            if let _ = imageURLS {
                showForegroundDataAlert(imageUrls: imageURLS!)
            }
        } else {
            let content = UNMutableNotificationContent()
            let requestIdentifier = "Fence"
            content.badge = 0
            content.title = "Fence Region"
            content.body = alert
            content.sound = UNNotificationSound.default
            if let _ = imageURLS {
                content.userInfo = ["imgurls":imageURLS!]
                content.title = "HSTRY"
                content.body = "There is HSTRY here! Click to see!"
            }
            
            let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 1.0, repeats: false)
            let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { (error:Error?) in
                print("Notification Register Success")
            }
        }
    }
 
}

extension LocationService {
  
    func checkDistanceBetweenCoordinates() -> Bool {
        var isDistanceGreater = false
        if let prevLoc = previousLocation, let currLoc = currentLocation {
            isDistanceGreater =  (prevLoc.distance(from: currLoc) > 20.0) ? true : false
        }
        return isDistanceGreater
        
    }

    func regionHandlingInForeground() {
        AppDelegate.ref.child("Regions").observeSingleEvent(of: .value) { snapshot in
            if let tempDic : Dictionary = snapshot.value as? Dictionary<String,Any> {
                self.filteredRegions = [[String: Any]]()
                for key in tempDic.keys {
                    let selectedDic = tempDic[key] as! Dictionary<String,Any>
                    let latittude = selectedDic["Latitude"] as! Double
                    let longitude = selectedDic["Longitude"] as! Double
                    let coords = CLLocationCoordinate2D(latitude: latittude, longitude: longitude)
                    
                    if let currentLoc = self.previousLocation {
                        let hstryHotspotRegion = CLCircularRegion(center:currentLoc.coordinate, radius: AppDelegate.localGPSRadius, identifier: "hstryHotspotRegion")
                        if hstryHotspotRegion.contains(coords) {
                            self.filteredRegions.append(selectedDic)
                        }
                    }
                }
                if let selctedRgionID = self.minimumDistanceBetweenCoordinates(arrRegions: self.filteredRegions,currentLocation: self.currentLocation) {
                    if selctedRgionID != self.lastSavedHstryRegionID {
                        self.lastSavedHstryRegionID = selctedRgionID
                        self.fetchDataInRegion(regionIdentifier: selctedRgionID) { isData in
                            
                        }
                    }
                }
            }
        }
    }

    func checkContinuousRegionForLocationUpdate() {
        if let selctedRgionID = self.minimumDistanceBetweenCoordinates(arrRegions: self.filteredRegions,currentLocation: self.currentLocation) {
            if selctedRgionID != self.lastSavedHstryRegionID {
                self.lastSavedHstryRegionID = selctedRgionID
                self.fetchDataInRegion(regionIdentifier: selctedRgionID) { isData in
                    
                }
            }
        }
    }
    
    func dataActiveState(region: CLCircularRegion,  completion: @escaping ((Bool) -> Void)) {
        AppDelegate.ref.child("Regions").observeSingleEvent(of: .value) { snapshot in
            
            if let tempDic : Dictionary = snapshot.value as? Dictionary<String,Any> {
                var hstryHotspotRegionList = [[String: Any]]()
                for key in tempDic.keys {
                    let selectedDic = tempDic[key] as! Dictionary<String,Any>
                    let latittude = selectedDic["Latitude"] as! Double
                    let longitude = selectedDic["Longitude"] as! Double
                    let coords = CLLocationCoordinate2D(latitude: latittude, longitude: longitude)
                    
                    if region.contains(coords) {
                        /// Check if user lcurrent location is in the HSTRY region, if so, trigger notification
                        if let currentLocation = self.myLocation {
                            let hstryHotspotRegion = CLCircularRegion(center: coords, radius: AppDelegate.localGPSRadius, identifier: "hstryHotspotRegion")
                            if hstryHotspotRegion.contains(currentLocation.coordinate) {
                                hstryHotspotRegionList.append(selectedDic)
                            }
                        }
                    }
                }
                if let selctedRgionID = self.minimumDistanceBetweenCoordinates(arrRegions: hstryHotspotRegionList,currentLocation: self.myLocation) {
                    self.fetchDataInRegion(regionIdentifier: selctedRgionID) { isData in
                        completion(isData)
                    }
                } else {
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }
    
    func clearAllForegroundRegions() {
        manager.stopUpdatingLocation()
        previousLocation = nil
        currentLocation = nil
        filteredRegions.removeAll()
        lastSavedHstryRegionID = nil
    }
}

extension LocationService: FCAlertViewDelegate {
    func showForegroundDataAlert(imageUrls: [String]) {
        if let topViewC = UIApplication.getTopViewController() {
            //alert.removeFromSuperview()
            if let foundView = topViewC.view.window?.viewWithTag(100) {
                foundView.removeFromSuperview()
                alert = nil
            }
            alert = FCAlertView()
            
            alert!.delegate = self
            alert!.addButton("Dismiss") {
                
            }
            alert!.addButton("Show") { [weak self] in
                self?.navigateGalleryScreen(imageURLS: imageUrls)
            }
            alert!.tag = 100
            alert!.dismissOnOutsideTouch = false
            alert!.overrideForcedDismiss = true
            alert!.hideDoneButton = true
            alert!.showAlert(inView: topViewC,
                             withTitle: "HSTRY",
                             withSubtitle: "There is HSTRY here! Click to see",
                             withCustomImage: nil,
                             withDoneButtonTitle: nil,
                             andButtons: nil)
        }
        
    }
        
}
