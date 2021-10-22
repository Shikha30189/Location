//
//  LocationViewController.swift
//  Location
//
//  Created by shikha on 26/07/21.
//

import UIKit
import MapKit

class LocationViewController: UIViewController, MKMapViewDelegate {
    @IBOutlet var mapView: MKMapView!
    var locationServiceObject: LocationService!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate =  self
        self.mapView.showsUserLocation = true
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        locationServiceObject = appDelegate.locationServiceObject
        locationServiceObject.getLocation() { [weak locationServiceObject] result in
            if locationServiceObject?.manager.monitoredRegions.count == 0,
               case let .success(latestLocation) = result {
                locationServiceObject?.initialiseAllRegions(with: latestLocation.coordinate)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        DispatchQueue.once {
            let region = MKCoordinateRegion.init(center: userLocation.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
            mapView.setRegion(mapView.regionThatFits(region), animated: true)
        }
    }
}

public extension DispatchQueue {
    private static var _onceTracker = [String]()
    class func once(file: String = #file, function: String = #function, line: Int = #line, block:()->Void) {
        let token = file + ":" + function + ":" + String(line)
        once(token: token, block: block)
    }
    /**
     Executes a block of code, associated with a unique token, only once.  The code is thread safe and will
     only execute the code once even in the presence of multithreaded calls.
     - parameter token: A unique reverse DNS style name such as com.vectorform.<name> or a GUID
     - parameter block: Block to execute once
     */
    class func once(token: String, block:()->Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        if _onceTracker.contains(token) {
            return
        }
        _onceTracker.append(token)
        block()
    }
}
