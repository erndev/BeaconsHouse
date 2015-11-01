//
//  BeaconListener.swift
//  BeaconsHouse
//
//  Created by Ernesto García on 01/11/15.
//  Copyright © 2015 erndev. All rights reserved.
//

import CoreLocation

enum Status {
  case Authorized
  case NotDetermined
  case NotAuthorized
}

protocol HouseBeaconsDelegate {
  
  func coreLocationAuthorization( status:Status )
  func foundBeacons( beacons:[UInt] )
  func errorScanning(error:NSError)
}

class HouseBeaconsManager : NSObject {
  

  
  private struct Constants {
    
    static let HouseBeaconsUUID = "163EB541-B100-4BA5-8652-EB0C513FB0F4"
    static let HouseIconMajor:Int32 = 10
    static let RegionIdentifier = "housebeaconsRegion"
  }
  
  var beaconRegion:CLBeaconRegion?
  let locationManager:CLLocationManager
  var delegate:HouseBeaconsDelegate?
  var lastKnownBeacon:CLBeacon?
  
  override init() {
    
    locationManager = CLLocationManager()
    if let uuid = NSUUID(UUIDString:Constants.HouseBeaconsUUID) {
      beaconRegion = CLBeaconRegion(proximityUUID: uuid, major: CLBeaconMajorValue(Constants.HouseIconMajor), identifier: Constants.HouseBeaconsUUID )
    }
    super.init()
    locationManager.delegate = self
  }
  
  func start() {
    print ("Start")
    guard let beaconRegion = beaconRegion else {
      return;
    }
    // region for all the beacuse with major ID.
    locationManager.startMonitoringForRegion(beaconRegion)
    locationManager.startRangingBeaconsInRegion(beaconRegion)
  }
  
  func stop() {
    
    print ("Stop")
    guard let beaconRegion = beaconRegion else {
      return;
    }
    locationManager.stopRangingBeaconsInRegion(beaconRegion)
    locationManager.stopMonitoringForRegion(beaconRegion)
  }
  
  private func statusFromCorelocationAuthStatus(status:CLAuthorizationStatus) -> Status {
    var myStatus:Status = .NotAuthorized
    if  (status == .AuthorizedAlways || status == .AuthorizedWhenInUse )
    {
      myStatus = .Authorized
    }
    else if (status == .NotDetermined)
    {
      myStatus = .NotDetermined
    }
    return myStatus
  }
  
  func authorization() -> Status  {
    
    return statusFromCorelocationAuthStatus(CLLocationManager.authorizationStatus())
    
  }
  
  func requestAuthorization() {
    locationManager.requestAlwaysAuthorization()
  }
}


extension HouseBeaconsManager : CLLocationManagerDelegate {
  
  func isHouseBeacon(beacon:CLBeacon) -> Bool {
    guard  beacon.proximityUUID.UUIDString == Constants.HouseBeaconsUUID &&
      beacon.major.intValue == Constants.HouseIconMajor else {
        return false
    }
    
    
    return true
  }
  
  func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
    print("Beacons found")
    
    
    let houseBeacons = beacons.filter{ isHouseBeacon($0) }.map{ UInt($0.minor.integerValue) }
    delegate?.foundBeacons(houseBeacons)
  }
  
  func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
    print("Did enter region")
  }
  
  func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
    print("Did exit region")
  }
  
  func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    print("Authorization Status changed with value: \(status)")
    delegate?.coreLocationAuthorization(statusFromCorelocationAuthStatus(status))
  }
  
  func  locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
    print("Error monitoring beacon region: \(error)")
    delegate?.errorScanning(error)
  }
  
  func locationManager(manager: CLLocationManager, rangingBeaconsDidFailForRegion region: CLBeaconRegion, withError error: NSError) {
    print("Erorr ranging beeacons: \(error)")
    delegate?.errorScanning(error)
  }
  
}