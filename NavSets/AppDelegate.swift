//
//  AppDelegate.swift
//  NavSets
//
//  Created by Adam Greenstein on 11/27/17.
//  Copyright © 2017 Max Schuman. All rights reserved.
//

import UIKit
import Stripe

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    private let publishableKey: String = "pk_test_kTea5Cdlc5400AxWJJC6RNiS"
//    private let baseURLString: String = "https://nav-sets.herokuapp.com/"
    private let baseURLString: String = "https://gentle-retreat-10812.herokuapp.com/"
    
    // Stripe config init
    override init() {
        super.init()
        // Stripe payment configuration
        let config = STPPaymentConfiguration.shared()
        config.companyName = "NavSets"
        config.publishableKey = publishableKey
        config.requiredBillingAddressFields = .full
        config.appleMerchantIdentifier = "merchant.com.navsets"
        // Main API client configuration
        StripeAPIClient.sharedClient.baseURLString = baseURLString
    }
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        self.window = UIWindow(frame: UIScreen.main.bounds)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        var initialViewController = storyboard.instantiateViewController(withIdentifier: "BaseViewController")
        // Determine the view we should start with
        var firstLaunch = UserDefaults.standard.bool(forKey: "firstLaunch")
        // TEMPORARILY make firstLaunch always true so can view setup walkthrough screen without uninstalling app
//        firstLaunch = true
        if firstLaunch  {
            print("First launch, setting UserDefault")
            initialViewController = storyboard.instantiateViewController(withIdentifier: "StartupViewController")
            UserDefaults.standard.set(false, forKey: "firstLaunch")
            firstLaunch = false
        } else {
            // Don't update the initial view controller
            print("Not first launch")
        }
        self.window?.rootViewController = initialViewController
        self.window?.makeKeyAndVisible()
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
}

