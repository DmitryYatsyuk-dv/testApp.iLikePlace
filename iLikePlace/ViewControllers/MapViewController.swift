//
//  MapViewController.swift
//  FavoritePlaces
//
//  Created by Lucky on 07/02/2020.
//  Copyright © 2020 DmitriyYatsyuk. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

protocol MapViewControllerDelegate {
    func getAddress(_ address: String?)
}

class MapViewController: UIViewController {
    
    var mapManager = MapManager()
    var mapViewControllerDelegate: MapViewControllerDelegate?
    var place = Place()
    
    let annotationIdentifier = "annotationIdentifier"
    var incomeSegueIdentifier = ""
    
    var previousLocation: CLLocation? {
        didSet {
            mapManager.startTrackingUserLocation(for: mapView,
                                                 and: previousLocation) { (currentLocation) in
                                                    
                                                    self.previousLocation = currentLocation
                                                    
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                                        self.mapManager.showUserLocation(mapView: self.mapView)
                                                    }
            }
        }
    }
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapPin: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var infoRoute: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        infoRoute.isHidden = true
        infoRoute.backgroundColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 0.5)
        
        addressLabel.text = ""
        mapView.delegate = self
        setupMapView()
    }
    
    @IBAction func centerViewInUserLocation(_ sender: UIButton) {
        mapManager.showUserLocation(mapView: mapView)
    }
    
    @IBAction func goButtonPressed() {
        mapManager.getDirection(for: mapView) { (location) in
            self.previousLocation = location
        }
    }
    
    @IBAction func doneButtonPressed(_ sender: UIButton) {
        mapViewControllerDelegate?.getAddress(addressLabel.text)
        dismiss(animated: true)
    }
    
    @IBAction func closeVC(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    private func setupMapView() {
        
        goButton.isHidden = true
        
        mapManager.checkLocationServices(mapView: mapView, segueIdentifier: incomeSegueIdentifier) {
            mapManager.locationManager.delegate = self
        }
        
        if incomeSegueIdentifier == "showPlace" {
            mapManager.setupPlacemark(place: place, mapView: mapView)
            mapPin.isHidden = true
            addressLabel.isHidden = true
            doneButton.isHidden = true
            goButton.isHidden = false
        }
    }
    
    deinit {
        print("deinit", MapViewController.self)
    }
    
}

extension MapViewController: MKMapViewDelegate {
    
    // The method shows annotation
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard !(annotation is MKUserLocation) else { return nil }
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as? MKPinAnnotationView
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation,
                                                 reuseIdentifier: annotationIdentifier)
            annotationView?.canShowCallout = true
        }
        
        // Add image to annotation
        if let imageData = place.imageData {
            
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            imageView.layer.cornerRadius = 10
            imageView.clipsToBounds = true
            imageView.image = UIImage(data: imageData)
            annotationView?.rightCalloutAccessoryView = imageView
        }
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        let center = mapManager.getCenterLocation(for: mapView)
        let geocoder = CLGeocoder()
        
        if incomeSegueIdentifier == "showPlace" && previousLocation != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.mapManager.showUserLocation(mapView: self.mapView)
            }
        }
        
        geocoder.cancelGeocode()
        
        geocoder.reverseGeocodeLocation(center) { (placemarks, error) in
            
            if let error = error {
                print(error)
                return
            }
            
            guard let placemarks = placemarks else { return }
            
            let placemark = placemarks.first
            let streetName = placemark?.thoroughfare
            let buildNumber = placemark?.subThoroughfare
            
            DispatchQueue.main.async {
                
                if streetName != nil, buildNumber != nil {
                    
                    self.addressLabel.text = "\(streetName!), \(buildNumber!)"
                } else if streetName != nil {
                    self.addressLabel.text = "\(streetName!)"
                } else {
                    self.addressLabel.text = ""
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        
        return renderer
    }
}

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        
        mapManager.checkLocationAuthorization(mapView: mapView,
                                              segueIdentifier: incomeSegueIdentifier)
    }
}



