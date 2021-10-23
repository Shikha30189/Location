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
    static let innerRadiusKey = "InnerRadius"
    static let outerRadiusKey = "OuterRadius"
    static var localGPSRadius = 20.0
    var notificationImageURL: [String]?
    var notificationRegionId: String?


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
        if locationServiceObject.status == .authorizedAlways {
            locationServiceObject.onAppForeground()
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        if locationServiceObject.status == .authorizedAlways {
            locationServiceObject.onAppBackground()
        }
    }
//    func applicationWillEnterForeground(_ application: UIApplication) {
//        
//    }
//    
//    func applicationDidEnterBackground(_ application: UIApplication) {
//    }
}



