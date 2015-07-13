//
//  ReverseGeocoderOperation.swift
//  waterlogged
//
//  Created by Tim Shadel on 7/12/15.
//  Copyright © 2015 Day Logger, Inc. All rights reserved.
//

import Foundation
import CoreLocation

private var CLGeocoderOperationKVOContext = 0

/**
`CLGeocoderOperation` is an `Operation` that lifts a `CLGeocoder`
into an operation.

Note that this operation does not receive any of the callbacks
of `CLGeocoder`, but instead uses Key-Value-Observing to know when the
geocoder has been completed.
*/
public class CLGeocoderOperation: Operation {
    let geocoder: CLGeocoder
    let completionHandler: CLGeocodeCompletionHandler
    let location: CLLocation?
    let addressDictionary: [NSObject:AnyObject]?
    let addressString: String?
    let addressRegion: CLRegion?
    let useAddressRegion: Bool

    public init(location: CLLocation, completionHandler: CLGeocodeCompletionHandler) {
        self.geocoder = CLGeocoder()
        self.completionHandler = completionHandler
        self.location = location
        self.addressDictionary = nil
        self.addressString = nil
        self.addressRegion = nil
        self.useAddressRegion = false
        super.init()
    }

    public init(addressDictionary: [NSObject:AnyObject], completionHandler: CLGeocodeCompletionHandler) {
        self.geocoder = CLGeocoder()
        self.completionHandler = completionHandler
        self.location = nil
        self.addressDictionary = addressDictionary
        self.addressString = nil
        self.addressRegion = nil
        self.useAddressRegion = false
        super.init()
    }

    public init(addressString: String, completionHandler: CLGeocodeCompletionHandler) {
        self.geocoder = CLGeocoder()
        self.completionHandler = completionHandler
        self.location = nil
        self.addressDictionary = nil
        self.addressString = addressString
        self.addressRegion = nil
        self.useAddressRegion = false
        super.init()
    }

    public init(addressString: String, inRegion addressRegion: CLRegion?, completionHandler: CLGeocodeCompletionHandler) {
        self.geocoder = CLGeocoder()
        self.completionHandler = completionHandler
        self.location = nil
        self.addressDictionary = nil
        self.addressString = addressString
        self.addressRegion = addressRegion
        self.useAddressRegion = true
        super.init()
    }

    override func execute() {
        geocoder.addObserver(self, forKeyPath: "geocoding", options: [], context: &CLGeocoderOperationKVOContext)

        if let location = location {
            geocoder.reverseGeocodeLocation(location, completionHandler: completionHandler)
        } else if let addressDictionary = addressDictionary {
            geocoder.geocodeAddressDictionary(addressDictionary, completionHandler: completionHandler)
        } else if let addressString = addressString {
            if useAddressRegion {
                geocoder.geocodeAddressString(addressString, inRegion: addressRegion, completionHandler: completionHandler)
            } else {
                geocoder.geocodeAddressString(addressString, completionHandler: completionHandler)
            }
        }
    }

    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard context == &CLGeocoderOperationKVOContext else { return }

        if object === geocoder && keyPath == "geocoding" && geocoder.geocoding == false {
            geocoder.removeObserver(self, forKeyPath: "geocoding")
            finish()
        }
    }

    override public func cancel() {
        geocoder.cancelGeocode()
        super.cancel()
    }
}
