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

    var ref: DatabaseReference!

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
//        registerBackgroundTaks()
//        UIApplication.shared.setMinimumBackgroundFetchInterval(
//          UIApplication.backgroundFetchIntervalMinimum)
 
        IQKeyboardManager.shared.enable = true
        
        FirebaseApp.configure()
        ref = Database.database().reference()
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
    }
       
}



