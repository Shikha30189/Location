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
        locationServiceObject.getLocation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let region = MKCoordinateRegion.init(center: userLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
    }
}
