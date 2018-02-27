//
//  startupViewController.swift
//  NavSets
//
//  Created by Adam Greenstein on 2/24/18.
//  Copyright © 2018 Max Schuman. All rights reserved.
//

import UIKit
import Mapbox
import Stripe
import os.log

class StartupViewController: UIViewController, MGLMapViewDelegate, STPPaymentContextDelegate{
    //MARK: Properties
    var userModel: UserModel?
    var locationAccess: Bool!
    var mapView: MGLMapView!
    let paymentContext: STPPaymentContext
    let customerContext: STPCustomerContext
    @IBOutlet weak var setVehicle: UIButton!
    @IBOutlet weak var setPayment: UIButton!
    @IBOutlet weak var getStarted: UIButton!
    
    required init?(coder aDecoder: NSCoder) {
        customerContext = STPCustomerContext(keyProvider: MainAPIClient.sharedClient)
        paymentContext = STPPaymentContext(customerContext: customerContext)
        
        super.init(coder: aDecoder)
        paymentContext.delegate = self
        paymentContext.hostViewController = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load the user
        if let user = loadUser(){
            self.userModel = user
        }
        saveUser()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Navigation
    @IBAction func setupPayment(_ sender: Any) {
        self.paymentContext.presentPaymentMethodsViewController()
    }
    
    @IBAction func setupVehicle(_ sender: Any) {
        performSegue(withIdentifier: "vehicleSettings", sender: nil)
    }
    
    @IBAction func launchBaseView(_ sender: Any) {
        // Once setup is done, update the root view controller so we don't unwind back to the setup view
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let baseViewController = storyboard.instantiateViewController(withIdentifier: "BaseViewController")
        appDelegate.window = UIWindow(frame: UIScreen.main.bounds)
        appDelegate.window!.rootViewController = baseViewController
        appDelegate.window?.makeKeyAndVisible()
        performSegue(withIdentifier: "baseView", sender: nil)
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
    
    // MARK: STPPaymentContextDelegate - need these functions here but not actually doing anything
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        print("[ERROR]: Unrecognized error while loading payment context: \(error)");
    }
    
    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        print ("payment context changed")
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPErrorBlock) {
        print ("payment result created")
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {
        print ("payment finished with status")
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

