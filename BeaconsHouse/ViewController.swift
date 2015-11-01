//
//  ViewController.swift
//  BeaconsHouse
//
//  Created by Ernesto García on 01/11/15.
//  Copyright © 2015 erndev. All rights reserved.
//

import UIKit


enum HouseRoomMinor : UInt, CustomStringConvertible {
  case LivingRoom = 5
  case BedRoom    = 6
  case Kitchen    = 7
  
  var  description:String {
    var str = ""
    switch self {
    case .LivingRoom:
      str = "Living Room"
    case .BedRoom:
      str = "Bedroom"
    case .Kitchen:
      str = "Kitchen"
    }
    return str
  }
  
}

class ViewController: UITableViewController {
  
  struct Constants {
    
    static let BeaconSection = 1
    static let LocationRow = 0
    static let MinorRow = 1
    
  }
  
  @IBOutlet var locationImageView:UIImageView!
  @IBOutlet var locationTextField:UILabel!
  @IBOutlet var swithButton:UISwitch!
  
  let beaconManager =  HouseBeaconsManager()
  var shouldAutoStartAfterAuthorization = false
  var currentRoom:HouseRoomMinor?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    tableView.separatorInset = UIEdgeInsetsZero
    tableView.layoutMargins = UIEdgeInsetsZero
    beaconManager.delegate = self
    updateInfo()
  }
  
  
  
  func updateMinorText(text:String ) {
    
    updateDetailText(text, inRow: Constants.MinorRow, section: Constants.BeaconSection )
  }
  
  func updateDetailText( text:String, inRow row:Int, section:Int ) {
    
    if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: section) ) {
      cell.detailTextLabel?.text = text
    }
    
  }
  
  @IBAction func switchToggled( sender:UISwitch ) {
    
    
    if( swithButton.on ) {
      
      if beaconManager.authorization() == .NotDetermined {
        beaconManager.requestAuthorization()
        shouldAutoStartAfterAuthorization = true
        sender.on = false
        return
      }
      start()
    }
    else {
      stop()
    }
  }
  
  func start() {
    beaconManager.start()
  }
  
  func stop() {
    beaconManager.stop()
    swithButton.on = false
    updateInfo()
  }
  
  func updateInfo(room:HouseRoomMinor?=nil) {
    
    
    
    var minorText = ""
    var roomImage = UIImage(named: swithButton.on ?  "walk" : "switch" )
    var roomName =  swithButton.on ?  "Walk to find Beacons" : "Enable scanning to find Beacons"
    
    
    if let room = room {
      minorText = String(room.rawValue)
      roomName = room.description
      roomImage = UIImage(named: "room-" + minorText )
    }

    
    updateMinorText(minorText)
    UIView.transitionWithView(locationImageView, duration:0.4, options: .TransitionCrossDissolve,  animations: { () -> Void in
      self.locationImageView.image = roomImage

      }, completion: nil)
    
    locationTextField.text = roomName
    
    currentRoom = room
    
    tableView .beginUpdates()
    tableView.endUpdates()
    
    
  }
  
  override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    if( indexPath.row == Constants.MinorRow && currentRoom == nil ) {
      return 0
    }
    return super.tableView(tableView , heightForRowAtIndexPath: indexPath)
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell =  super.tableView(tableView, cellForRowAtIndexPath: indexPath)
    cell.layoutMargins = UIEdgeInsetsZero
    return cell
  }
}


extension ViewController : HouseBeaconsDelegate {
  
  
  func errorScanning(error: NSError) {
    NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
      self.swithButton.on = false
      self.stop()
      
      let errorController  = UIAlertController(title: "Error scanning", message: error.localizedDescription, preferredStyle: .Alert)
      errorController.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
      self.presentViewController(errorController, animated: true, completion: nil)
    }
    
  }
  
  
  func foundBeacons(beacons: [UInt]) {
    
    NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
      var room:HouseRoomMinor?
      // Just get the first known beacon
      for beacon in beacons {
        if let beaconRoom = HouseRoomMinor(rawValue: beacon) {
          print("Found beacon in \(beaconRoom.description)")
          room = beaconRoom
          break
        }
      }
      self.updateInfo(room)
    }
    
  }
  
  func coreLocationAuthorization( status:Status ) {
    NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
      self.swithButton.enabled = (status != .NotAuthorized)
      if( status == .Authorized &&  self.shouldAutoStartAfterAuthorization ) {
        self.start()
      }
      self.shouldAutoStartAfterAuthorization = false
    }
    
  }
  
}


