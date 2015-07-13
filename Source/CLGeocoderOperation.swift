//
//  ReverseGeocoderOperation.swift
//  waterlogged
//
//  Created by Tim Shadel on 7/12/15.
//  Copyright © 2015 Day Logger, Inc. All rights reserved.
//

import Foundation
import CoreLocation


public enum CLGeocoderOperationType {
    case ReverseGeocodeLocation(CLLocation)
    case ForwardGeocodeAddressDictionary([NSObject:AnyObject])
    case ForwardGeocodeAddressString(String)
    case ForwardGeocodeAddressStringInRegion(String, CLRegion?)
}


/**
`CLGeocoderOperation` is an `Operation` that lifts a `CLGeocoder`
into an operation.
*/
public class CLGeocoderOperation: Operation {
    let geocoder: CLGeocoder
    let completionHandler: CLGeocodeCompletionHandler
    let geocodeType: CLGeocoderOperationType


    public init(geocodeType: CLGeocoderOperationType, completionHandler: CLGeocodeCompletionHandler) {
        self.geocoder = CLGeocoder()
        self.geocodeType = geocodeType
        self.completionHandler = completionHandler
        super.init()
    }

    convenience public init(location: CLLocation, completionHandler: CLGeocodeCompletionHandler) {
        self.init(geocodeType: .ReverseGeocodeLocation(location), completionHandler: completionHandler)
    }

    convenience public init(addressDictionary: [NSObject:AnyObject], completionHandler: CLGeocodeCompletionHandler) {
        self.init(geocodeType: .ForwardGeocodeAddressDictionary(addressDictionary), completionHandler: completionHandler)
    }

    convenience public init(addressString: String, completionHandler: CLGeocodeCompletionHandler) {
        self.init(geocodeType: .ForwardGeocodeAddressString(addressString), completionHandler: completionHandler)
    }

    convenience public init(addressString: String, inRegion addressRegion: CLRegion?, completionHandler: CLGeocodeCompletionHandler) {
        self.init(geocodeType: .ForwardGeocodeAddressStringInRegion(addressString, addressRegion), completionHandler: completionHandler)
    }

    override func execute() {
        switch geocodeType {
        case .ReverseGeocodeLocation(let location):
            geocoder.reverseGeocodeLocation(location, completionHandler: completionHandler)
        case .ForwardGeocodeAddressDictionary(let addressDictionary):
            geocoder.geocodeAddressDictionary(addressDictionary, completionHandler: completionHandler)
        case .ForwardGeocodeAddressString(let addressString):
            geocoder.geocodeAddressString(addressString, completionHandler: completionHandler)
        case .ForwardGeocodeAddressStringInRegion(let addressString, let addressRegion):
            geocoder.geocodeAddressString(addressString, inRegion: addressRegion, completionHandler: completionHandler)
        }
    }

    override public func cancel() {
        geocoder.cancelGeocode()
        super.cancel()
    }
}
