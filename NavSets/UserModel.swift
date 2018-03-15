//
//  UserModel.swift
//  NavSets
//
//  Created by user133102 on 11/30/17.
//  Copyright © 2017 Max Schuman. All rights reserved.
//

import Mapbox
import MapboxDirections

struct PropertyKey{
    static let carMake = "carMake"
    static let carModel = "carModel"
    static let carYear = "carYear"
    static let CO2GramsPerMile = "CO2GramsPerMile"
    static let stripeID = "stripeID"
    static let cumulativeCost = "cumulativeCost"
    static let totalOffsetHistory = "totalOffsetHistory"
}

class UserModel: NSObject, NSCoding{
    //MARK: Archiving Paths
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("user")
    
    // MARK: Properties
    // Can tack on additional properties as necessary
    var carMake: String?
    var carModel: String?
    var carYear: String?
    var stripeID: String?
    var cumulativeCost: Int
    var totalOffsetHistory: Int
    
    var CO2GramsPerMile: Float?
    let EMISSIONSCONSTANT: Float = 500.0
    
    // MARK: Initialization
    override init() {
        carMake = nil
        carModel = nil
        carYear = nil
        CO2GramsPerMile = nil
        stripeID = nil
        cumulativeCost = 0
        totalOffsetHistory = 0
    }
    
    init?(carMake: String, carModel: String, carYear: String, cumulativeCost: Int, totalOffsetHistory: Int){
        self.carMake = carMake
        self.carModel = carModel
        self.carYear = carYear
        self.cumulativeCost = cumulativeCost
        self.totalOffsetHistory = totalOffsetHistory
    }
    
    init?(carMake: String?, carModel: String?, carYear: String?, gramsPerMile: Float?, stripeID: String?, cumulativeCost: Int?, totalOffsetHistory: Int?){
        self.carMake = carMake
        self.carModel = carModel
        self.carYear = carYear
        self.CO2GramsPerMile = gramsPerMile
        self.stripeID = stripeID
        self.cumulativeCost = cumulativeCost ?? 0
        self.totalOffsetHistory = totalOffsetHistory ?? 0
    }
    
    //MARK: Methods
    func offsetCost(route: Route) -> Double{
        let emissions = self.CO2GramsPerMile ?? EMISSIONSCONSTANT
        
        let distanceMeters = Float(route.distance)
        let metersToMiles = Float(0.000621371)
        let gramsToPounds = Float(0.00220462)
        let poundsToCents = Float(0.00499)
        
        let cost = distanceMeters * metersToMiles * emissions * gramsToPounds * poundsToCents
        //return greater of cost or one cent
        return max(Double(round(100 * Double(cost))/100), 0.01)
        
        
    }
    
    
    //MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(carMake, forKey: PropertyKey.carMake)
        aCoder.encode(carModel, forKey: PropertyKey.carModel)
        aCoder.encode(carYear, forKey: PropertyKey.carYear)
        aCoder.encode(CO2GramsPerMile, forKey: PropertyKey.CO2GramsPerMile)
        aCoder.encode(stripeID, forKey: PropertyKey.stripeID)
        aCoder.encode(cumulativeCost, forKey: PropertyKey.cumulativeCost)
        aCoder.encode(totalOffsetHistory, forKey: PropertyKey.totalOffsetHistory)
    }
    
    required convenience init?(coder aDecoder: NSCoder){
        let carMake = aDecoder.decodeObject(forKey: PropertyKey.carMake) as? String
        let carModel = aDecoder.decodeObject(forKey: PropertyKey.carModel) as? String
        let carYear = aDecoder.decodeObject(forKey: PropertyKey.carYear) as? String
        let emissions = aDecoder.decodeObject(forKey: PropertyKey.CO2GramsPerMile) as? Float
        let stripeID = aDecoder.decodeObject(forKey: PropertyKey.stripeID) as? String
        let cumulativeCost = aDecoder.decodeObject(forKey: PropertyKey.cumulativeCost) as? Int
        let totalOffsetHistory = aDecoder.decodeObject(forKey: PropertyKey.totalOffsetHistory) as? Int
        
        self.init(carMake: carMake, carModel: carModel, carYear: carYear, gramsPerMile: emissions, stripeID: stripeID, cumulativeCost: cumulativeCost, totalOffsetHistory: totalOffsetHistory)
    }
    
}
