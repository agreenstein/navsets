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
    @IBOutlet weak var vehicleMakeAndModel: UIButton!
    @IBOutlet weak var getStarted: UIButton!
    @IBOutlet weak var carButton: UIButton!
    @IBOutlet weak var suvButton: UIButton!
    @IBOutlet weak var truckButton: UIButton!
    
    // emissions constants
    let carCO2GramsPerMile = Float(375.3)
    let suvCO2GramsPerMile = Float(406.6)
    let truckCO2GramsPerMile = Float(510.6)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locManager = CLLocationManager()
        locManager.delegate = self
        locManager.requestWhenInUseAuthorization()
        
        // load the user
        if let user = loadUser(){
            self.userModel = user
        }
        saveUser()
        
        // Hide the get started button until a vehicle type or model has been chosen
        self.getStarted.isHidden = true
        
        self.carButton.layer.cornerRadius = 7
        self.suvButton.layer.cornerRadius = 7
        self.truckButton.layer.cornerRadius = 7
        self.vehicleMakeAndModel.layer.cornerRadius = 7
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
            break
        case .authorizedWhenInUse, .authorizedAlways:
            // If authorized when in use
            manager.startUpdatingLocation()
            break
        case .restricted, .denied:
            // If restricted by e.g. parental controls. User can't enable Location Services
            // If user denied your app access to Location Services, they can grant access from Settings.app
            break
        }
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
    }
    
    
    @IBAction func selectVehicleType(_ sender: UIButton) {
        // deselect the make and model button
        vehicleMakeAndModel.isSelected = false
//        vehicleMakeAndModel.backgroundColor = UIColor.clear
        vehicleMakeAndModel.backgroundColor = UIColor.groupTableViewBackground
        vehicleMakeAndModel.setTitle("Select Make and Model", for: .normal)
        let transitButtons = [carButton, suvButton, truckButton, nil];
        for button in transitButtons {
            if (button == sender) {
                self.getStarted.isHidden = false
                button?.isSelected = true
                button?.backgroundColor = UIColor(red:0.16, green:0.54, blue:0.32, alpha:1.0)
            }
            else {
                button?.isSelected = false
//                button?.backgroundColor = UIColor.clear
                button?.backgroundColor = UIColor.groupTableViewBackground
            }
        }
        // update user model vehicle emissions
        switch sender{
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
        // deselect the transit buttons
        carButton.isSelected = false
//        carButton.backgroundColor = UIColor.clear
        carButton.backgroundColor = UIColor.groupTableViewBackground
        truckButton.isSelected = false
//        truckButton.backgroundColor = UIColor.clear
        truckButton.backgroundColor = UIColor.groupTableViewBackground
        suvButton.isSelected = false
//        suvButton.backgroundColor = UIColor.clear
        suvButton.backgroundColor = UIColor.groupTableViewBackground
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
        else{
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
            // Change the "set make and model" button to actually say the selected make and model
            let makeAndModel = user.carMake! + " " + user.carModel!
            self.vehicleMakeAndModel.setTitle(makeAndModel, for: .normal)
            // select the make and model button
            self.vehicleMakeAndModel.isSelected = true
            self.vehicleMakeAndModel.backgroundColor = UIColor(red:0.16, green:0.54, blue:0.32, alpha:1.0)
        }
    }
    
    // MARK: Private functions
    private func saveUser(){
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: self.userModel!, requiringSecureCoding: false)
            try data.write(to: UserModel.ArchiveURL)
            os_log("User successfully saved.", log: OSLog.default, type: .debug)
        } catch {
            os_log("Failed to save user...", log: OSLog.default, type: .error)
        }
    }
    
    private func loadUser() -> UserModel?  {
        if let nsData = NSData(contentsOfFile: UserModel.ArchiveURL.path) {
            do {
                let userData = Data(referencing:nsData)
                let user = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(userData) as? UserModel
                return user
            }
            catch {
                os_log("Failed to load user...", log: OSLog.default, type: .error)
            }
        }
        return self.userModel
    }
    
}

