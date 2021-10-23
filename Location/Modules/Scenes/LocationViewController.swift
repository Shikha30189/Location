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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate =  self
        self.mapView.showsUserLocation = true
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
