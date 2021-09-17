//
//  AppDelegate.swift
//  Location
//
//  Created by shikha on 09/07/21.
//

import UIKit
import IQKeyboardManagerSwift
import Firebase
import CoreLocation
import BackgroundTasks


@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var locationServiceObject: LocationService!
    
    //var ref: DatabaseReference!
    static let ref: DatabaseReference = Database.database().reference()
    static var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
    static var backgroundDataTaskId: UIBackgroundTaskIdentifier = .invalid
    static let innerRadiusKey = "InnerRadius"
    static let outerRadiusKey = "OuterRadius"


    
    
    
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let innerRadius = UserDefaults.standard.double(forKey: AppDelegate.innerRadiusKey)
        let outerRadius = UserDefaults.standard.double(forKey: AppDelegate.outerRadiusKey)

        if innerRadius == 0 || outerRadius == 0 {
            UserDefaults.standard.set(25.0, forKey: AppDelegate.innerRadiusKey)
            UserDefaults.standard.set(100.0, forKey: AppDelegate.outerRadiusKey)
        }

        //        registerBackgroundTaks()
        //        UIApplication.shared.setMinimumBackgroundFetchInterval(
        //          UIApplication.backgroundFetchIntervalMinimum)
        
        IQKeyboardManager.shared.enable = true
        
        FirebaseApp.configure()
        //ref = Database.database().reference()
        locationServiceObject = LocationService()
        let coords = CLLocationCoordinate2D(latitude: 25.99106021, longitude: 79.43888838)
        let region = CLCircularRegion(center: coords, radius: 100, identifier: "FenceCreate")
        //locationServiceObject.fetchData(region: region)
        //locationServiceObject.fetchDataInRegion(regionIdentifier: "92C59B75-B389-4A59-9F69-D257A4EF711F")
        
        window?.makeKeyAndVisible()
        return true
    }
    
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        let coords = CLLocationCoordinate2D(latitude: 25.99106021, longitude: 79.43888838)
        let region = CLCircularRegion(center: coords, radius: 100, identifier: "FenceCreate")
        
//        UIApplication.shared.beginBackgroundTask(withName: "Fetch Regions", expirationHandler: {
//            UIApplication.shared.endBackgroundTask(AppDelegate.backgroundTaskId)
//            AppDelegate.backgroundTaskId = .invalid
//        })
//
//
//        locationServiceObject.fetchDataInRegion(regionIdentifier: "92C59B75-B389-4A59-9F69-D257A4EF711F")
//            UIApplication.shared.endBackgroundTask(AppDelegate.backgroundTaskId)
//            AppDelegate.backgroundTaskId = .invalid
        
    }
    
}



