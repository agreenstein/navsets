//
//  startupViewController.swift
//  NavSets
//
//  Created by Adam Greenstein on 2/24/18.
//  Copyright © 2018 Max Schuman. All rights reserved.
//

import UIKit
import Mapbox
import os.log

class StartupViewController: UIViewController, MGLMapViewDelegate, CLLocationManagerDelegate{
    //MARK: Properties
    var locManager: CLLocationManager!
    var userModel: UserModel?
    var mapView: MGLMapView!
    var canShowUserLocation: Bool!
    var locationServicesDenied: Bool!
    @IBOutlet weak var setVehicle: UIButton!
    @IBOutlet weak var getStarted: UIButton!
    @IBOutlet weak var motorcycleButton: UIButton!
    @IBOutlet weak var carButton: UIButton!
    @IBOutlet weak var suvButton: UIButton!
    @IBOutlet weak var truckButton: UIButton!
    
    // emissions constants
    let carCO2GramsPerMile = Float(375.3)
    let motorcycleCO2GramsPerMile = Float(201.9)
    let suvCO2GramsPerMile = Float(406.6)
    let truckCO2GramsPerMile = Float(510.6)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locManager = CLLocationManager()
        locManager.delegate = self
        
        // load the user
        if let user = loadUser(){
            self.userModel = user
        }
        saveUser()
        
        // Hide the get started button until a vehicle type or model has been chosen
        self.getStarted.isHidden = true
        
        self.carButton.layer.cornerRadius = 7
        self.motorcycleButton.layer.cornerRadius = 7
        self.suvButton.layer.cornerRadius = 7
        self.truckButton.layer.cornerRadius = 7
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            // If status has not yet been determied, ask for authorization
            manager.requestWhenInUseAuthorization()
            locationServicesDenied = false
            break
        case .authorizedWhenInUse, .authorizedAlways:
            // If authorized when in use
            manager.startUpdatingLocation()
            locationServicesDenied = false
            break
        case .restricted, .denied:
            // If restricted by e.g. parental controls. User can't enable Location Services
            // If user denied your app access to Location Services, they can grant access from Settings.app
            locationServicesDenied = true
            break
        }
    }
    
    func checkLocationPrivileges(){
        locManager.requestWhenInUseAuthorization()
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
    }
    
    
    @IBAction func selectVehicleType(_ sender: UIButton) {
        let transitButtons = [motorcycleButton, carButton, suvButton, truckButton, nil];
        for button in transitButtons {
            if (button == sender) {
                self.getStarted.isHidden = false
                button?.isSelected = true
                button?.backgroundColor = UIColor(red:0.16, green:0.54, blue:0.32, alpha:1.0)
            }
            else {
                button?.isSelected = false
                button?.backgroundColor = UIColor.clear
            }
        }
        // update user model vehicle emissions
        switch sender{
        case motorcycleButton:
            self.userModel?.CO2GramsPerMile = motorcycleCO2GramsPerMile
        case carButton:
            self.userModel?.CO2GramsPerMile = carCO2GramsPerMile
        case truckButton:
            self.userModel?.CO2GramsPerMile = truckCO2GramsPerMile
        case suvButton:
            self.userModel?.CO2GramsPerMile = suvCO2GramsPerMile
        default:
            print ("No selected vehicle type")
        }
        saveUser()
    }
    
    @IBAction func setupVehicleMakeAndModel(_ sender: Any) {
        self.getStarted.isHidden = false
        performSegue(withIdentifier: "vehicleSettings", sender: nil)
    }
    
    @IBAction func launchBaseView(_ sender: Any) {
        checkLocationPrivileges()
        if (canShowUserLocation! == true){
            // Once setup is done, update the root view controller so we don't unwind back to the setup view
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let baseViewController = storyboard.instantiateViewController(withIdentifier: "BaseViewController")
            appDelegate.window = UIWindow(frame: UIScreen.main.bounds)
            appDelegate.window!.rootViewController = baseViewController
            appDelegate.window?.makeKeyAndVisible()
            performSegue(withIdentifier: "baseView", sender: nil)
        }
        else if (locationServicesDenied){
            let title = "Location Services Not Enabled"
            let message = "Please allow NavSets to access your location.  This can be updated in the Settings app."
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(action)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        saveUser()
        switch(segue.identifier ?? ""){
        case "vehicleSettings":
            guard let destination = segue.destination.childViewControllers.first as? SettingsViewController else {
                fatalError("Invalid destination controller: \(segue.destination)")
            }
            // update user model object for passing to settings view
            if let user = self.userModel{
                destination.userModel = user
            }
            else{
                self.userModel = UserModel()
                destination.userModel = self.userModel
            }
        case "baseView":
            guard let destination = segue.destination as? BaseViewController else {
                fatalError("Invalid destination controller: \(segue.destination)")
            }
            if let user = self.userModel{
                destination.userModel = user
            }
            else{
                self.userModel = UserModel()
                destination.userModel = self.userModel
            }
        default:
            print ("Unrecognized segue identifier")
        }
    }
    
    
    //MARK: Actions
    @IBAction func unwindToSelector(sender: UIStoryboardSegue){
        if let sourceViewController = sender.source as? SettingsViewController, let user = sourceViewController.userModel {
            // set user model to be the model from the previous view
            self.userModel = user
            saveUser()
        }
    }
    
    // MARK: Private functions
    
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

