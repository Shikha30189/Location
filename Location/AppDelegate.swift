//
//  AppDelegate.swift
//  Location
//
//  Created by shikha on 09/07/21.
//

import UIKit
import Firebase
import CoreLocation
import BackgroundTasks


@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var locationServiceObject: LocationService!
    static let ref: DatabaseReference = Database.database().reference()
    static var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
    static var backgroundDataTaskId: UIBackgroundTaskIdentifier = .invalid
    static let innerRadiusKey = "InnerRadius"
    static let outerRadiusKey = "OuterRadius"
    static let localGPSRadius = 20.0
    var imageURLS: [String]?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let innerRadius = UserDefaults.standard.double(forKey: AppDelegate.innerRadiusKey)
        let outerRadius = UserDefaults.standard.double(forKey: AppDelegate.outerRadiusKey)

        if innerRadius == 0 || outerRadius == 0 {
            UserDefaults.standard.set(100.0, forKey: AppDelegate.innerRadiusKey)
            UserDefaults.standard.set(500.0, forKey: AppDelegate.outerRadiusKey)
        }
        
        FirebaseApp.configure()
        locationServiceObject = LocationService()
        window?.makeKeyAndVisible()
        return true
    }
    
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        //fetch current Location and find the images in thae region
        locationServiceObject.manager.startUpdatingLocation()
        locationServiceObject.getLocation { [weak self] result in
            if case let .success(latestLocation) = result {
                let region = CLCircularRegion(center: latestLocation.coordinate, radius: (AppDelegate.localGPSRadius * 2.0), identifier: "abc")
                self?.locationServiceObject.dataActiveState(region: region, completion: { [weak self] isData in
                    if !isData, let urls = self?.imageURLS {
                        self?.locationServiceObject.navigateGalleryScreen(imageURLS: urls)
                    }
                })
            }
        }
        
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        locationServiceObject.clearAllForegroundRegions()
    }

}

extension UIApplication {

    class func getTopViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {

        if let nav = base as? UINavigationController {
            return getTopViewController(base: nav.visibleViewController)

        } else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return getTopViewController(base: selected)

        } else if let presented = base?.presentedViewController {
            return getTopViewController(base: presented)
        }
        return base
    }
}



