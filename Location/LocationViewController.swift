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
        locationServiceObject.newLocation = { result in
            switch result {
            case .success(let loc):
                print("location")
//                let region = MKCoordinateRegion.init(center: loc.coordinate, latitudinalMeters: 100, longitudinalMeters: 100)
//                self.mapView.setRegion(region, animated: true)
                // update location
            default:
                print("Error")
            }
          
        }

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)

    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        var region = MKCoordinateRegion.init(center: userLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        //self.mapView.setRegion(region, animated: true)
//        self.mapView.centerCoordinate = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
//        var region = MKCoordinateRegion.init(center: userLocation, span: 5)
//               // Avoid random spanning on the map by setting the region's span to be the same with the map's span
//               region.span = mapView.region.span
        mapView.setRegion(mapView.regionThatFits(region), animated: true)

    }
    
    

}
