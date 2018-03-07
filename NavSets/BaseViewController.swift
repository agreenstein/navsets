//
//  ViewController.swift
//  NavSets
//
//  Created by user133102 on 11/27/17.
//  Copyright © 2017 Max Schuman. All rights reserved.
//

import UIKit
import CoreLocation
import Mapbox
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import MapboxGeocoder
import os.log


class BaseViewController: UIViewController, UITextFieldDelegate, MGLMapViewDelegate, UITableViewDataSource, UITableViewDelegate{
    //MARK: Properties
    @IBOutlet weak var locationSearchTextField: UITextField!
    @IBOutlet weak var resultsTable: UITableView!
    @IBOutlet weak var currentLocationButton: UIButton!
    var mapView: MGLMapView!
    
    var routeModel: RouteModel?
    var userModel: UserModel?
    var canShowUserLocation: Bool!
    
    var geocoder: Geocoder!
    var geocodingDataTask: URLSessionDataTask?
    var forwardGeocodeResults: Array<GeocodedPlacemark>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // initialize route model with default arguments
        self.routeModel = RouteModel()
        
        // initialize user model with default arguments
        self.userModel = UserModel()
        
        // set self as delegate for text field
        locationSearchTextField.delegate = self
        locationSearchTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        // set up the results table
        resultsTable.delegate = self
        resultsTable.dataSource = self
        resultsTable.isHidden = true
        
        // Add map view to base view
        let url = URL(string: "mapbox://styles/mapbox/streets-v10")
        mapView = MGLMapView(frame: view.bounds, styleURL: url)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.setCenter(CLLocationCoordinate2D(latitude: 42.0493, longitude:-87.6819), zoomLevel: 11, animated: false)
        view.addSubview(mapView)
        view.sendSubview(toBack: mapView) // send the map view to the back, behind the other added UI elements
        
        // Set the map view's delegate
        mapView.delegate = self
        
        let setDestinationLP = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(_:)))
        mapView.addGestureRecognizer(setDestinationLP)
        
        // Add the geocoder
        geocoder = Geocoder.shared
        
        // Preload global data to speed up future use
        let shared = VehicleData.sharedInstance
        
        // Allow the map view to show the user's location and check the location privileges
        mapView.showsUserLocation = true
        checkLocationPrivileges()
        
        // load and authenticate the user
        if let user = loadUser(){
            self.userModel = user
        }
        var cust_id = ""
        if (self.userModel?.stripeID != nil){
            cust_id = (self.userModel?.stripeID)!
        }
        // add logic to check for internet connection?
        let auth_result = MainAPIClient.sharedClient.authenticate(customer: cust_id)
        if self.userModel?.stripeID != auth_result{
            self.userModel?.stripeID = auth_result
        }
        saveUser()
        
        // add rounding to corners of buttons
        self.resultsTable.layer.cornerRadius = 7
        self.currentLocationButton.layer.cornerRadius = self.currentLocationButton.frame.size.width / 2;
    }
    
    func checkLocationPrivileges(){
        if CLLocationManager.locationServicesEnabled()  {
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined, .restricted, .denied:
                canShowUserLocation = false
                print("No access")
            case .authorizedAlways, .authorizedWhenInUse:
                canShowUserLocation = true
                print("Access")
            }
        } else {
            print("Location services are not enabled")
            canShowUserLocation = false
        }
        if (canShowUserLocation! == true && mapView.userLocation?.coordinate.latitude != -180){
            mapView.setCenter((mapView.userLocation?.coordinate)!, zoomLevel: 11, animated: false)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        if (canShowUserLocation! == true){
            mapView.setCenter((mapView.userLocation?.coordinate)!, zoomLevel: 11, animated: false)
        }
    }
    
    @objc func didLongPress(_ sender: UILongPressGestureRecognizer){
        guard sender.state == .began else { return }
        // clear the previous annotations
        if (mapView.annotations != nil) {
            mapView.removeAnnotations(mapView.annotations!)
        }
        
        // Converts a point where user did a long press to map coordinates
        let point = sender.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        
        // Create a basic point annotation and add it to the map
        let annotation = MGLPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        self.routeModel!.destinationLocation = coordinate
        self.routeModel!.startLocation = mapView.userLocation?.coordinate
        
        geocodingDataTask?.cancel()
        let options = ReverseGeocodeOptions(coordinate: coordinate)
        geocodingDataTask = geocoder.geocode(options) { [unowned self] (placemarks, attribution, error) in
            if let error = error {
                NSLog("%@", error)
            } else if let placemarks = placemarks, !placemarks.isEmpty {
                self.locationSearchTextField.text = placemarks[0].qualifiedName
                // Segue to other view
                self.performSegue(withIdentifier: "LocationSelected", sender: self.mapView)
            } else {
                self.locationSearchTextField.text = "No results"
            }
        }
    }
    
    @IBAction func zoomToCurrentLocation(_ sender: UIButton) {
        if sender === currentLocationButton {
            if (canShowUserLocation! == true && mapView.userLocation?.coordinate.latitude != -180){
                mapView.setCenter((mapView.userLocation?.coordinate)!, zoomLevel: 11, animated: true)
                self.locationSearchTextField.text = "Current Location"
                self.routeModel!.startLocation = mapView.userLocation?.coordinate
            }
        }
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide keyboard
        textField.resignFirstResponder()
        // Clear view
        clearRouteModel()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = ""
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if (textField.text?.isEmpty)!{
            resultsTable.isHidden = true
        }
        else {
            resultsTable.isHidden = false
            geocodingDataTask?.cancel()
            let options = ForwardGeocodeOptions(query: locationSearchTextField.text!)
            options.focalLocation = CLLocation(latitude: (mapView.userLocation?.coordinate.latitude)!, longitude: (mapView.userLocation?.coordinate.longitude)!)
            options.maximumResultCount = 10
            geocodingDataTask = geocoder.geocode(options) { [unowned self] (placemarks, attribution, error) in
                if let error = error {
                    NSLog("%@", error)
                } else if let placemarks = placemarks, !placemarks.isEmpty {
                    self.forwardGeocodeResults = placemarks
                    DispatchQueue.main.async{
                        self.resultsTable.reloadData()
                    }
                } else {
                    print ("No results")
                }
            }
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
//        routeModel!.destinationName = textField.text
        resultsTable.isHidden = true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return forwardGeocodeResults?.count ?? 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "forwardGeocodeResult", for: indexPath)
        cell.textLabel?.text = forwardGeocodeResults?[indexPath.item].qualifiedName
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let placemark = forwardGeocodeResults?[indexPath.item]
            // make sure an actual location cell was selected
            if (placemark != nil){
            // Create a basic point annotation and add it to the map
            let annotation = MGLPointAnnotation()
            annotation.coordinate = (placemark?.location.coordinate)!
            mapView.addAnnotation(annotation)        // Update the route model and set the text in the search field
            self.routeModel!.destinationLocation = (placemark?.location.coordinate)!
            self.routeModel!.startLocation = mapView.userLocation?.coordinate
            self.locationSearchTextField.text = placemark?.qualifiedName
            // Segue to other view
            self.performSegue(withIdentifier: "LocationSelected", sender: self.resultsTable)
        }
    }
    
    
    //MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        // perform appropriate setup for destination controller
        let id = segue.identifier
        let destinationController = segue.destination
        switch(id ?? ""){
        case "LocationSelected":
            guard let destination = destinationController as? SelectorViewController else {
                fatalError("Invalid destination controller: \(segue.destination)")
            }
            // update route model object for passing to selector view
            // if the destination location hadn't been set yet, set it to the first geocoding result
            if (self.routeModel?.destinationLocation?.latitude == nil){
                self.routeModel?.destinationLocation = forwardGeocodeResults?.first?.location.coordinate
                self.routeModel!.startLocation = mapView.userLocation?.coordinate
                locationSearchTextField.text = forwardGeocodeResults?.first?.qualifiedName
            }
            if let destinationName = locationSearchTextField.text{
                self.routeModel!.destinationName = destinationName
                destination.routeModel = self.routeModel
                destination.userModel = self.userModel
            }
        
        default:
            fatalError("Did not recognize identifier: \(segue.identifier ?? "")")
        }
    }
    
    //MARK: Actions
    @IBAction func unwindToBase(sender: UIStoryboardSegue){
        if let sourceViewController = sender.source as? SelectorViewController, let routeModel = sourceViewController.routeModel, let user = sourceViewController.userModel {
            // set route model to be the model from the previous view
            self.routeModel = routeModel
            updateRouteModel()
            // set the user mdoel to be the model from the previous view
            self.userModel = user
            saveUser()
        }
    }
    
    //MARK: Private Methods
    private func updateRouteModel(){
        self.locationSearchTextField.text = routeModel?.destinationName
        // We can add code here that drops the pin on the map for the chosen location, sets the search bar to the location name, and centers the map on the chosen location
        // clear the previous annotations
        if (mapView.annotations != nil) {
            mapView.removeAnnotations(mapView.annotations!)
        }
        // Add an annotation for the destination
        let annotation = MGLPointAnnotation()
        annotation.coordinate = (routeModel?.destinationLocation)!
        mapView.addAnnotation(annotation)
        // Center the map on the destination
        mapView.setCenter((self.routeModel?.destinationLocation)!, zoomLevel: 11, animated: false)
    }
    
    private func clearRouteModel(){
        self.routeModel = nil
        
        self.locationSearchTextField.text = nil
        
        // Add code here that clears out everything on view impacted by route model
    }
    
    private func saveUser(){
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(self.userModel, toFile: UserModel.ArchiveURL.path)
        if isSuccessfulSave {
            os_log("User successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save user...", log: OSLog.default, type: .error)
        }
    }
    
    private func loadUser() -> UserModel?  {
        return NSKeyedUnarchiver.unarchiveObject(withFile: UserModel.ArchiveURL.path) as? UserModel
    }

}
