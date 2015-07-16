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
    case ReverseGeocodeLocationProvider(LocationProvider)
    case ForwardGeocodeAddressDictionary([NSObject:AnyObject])
    case ForwardGeocodeAddressString(String)
    case ForwardGeocodeAddressStringInRegion(String, CLRegion?)
}


/**
`CLGeocoderOperation` is an `Operation` that lifts a `CLGeocoder`
into an operation.
*/
public class CLGeocoderOperation: Operation {

    public var placemark: CLPlacemark?

    private let geocoder: CLGeocoder
    private let completionHandler: CLGeocodeCompletionHandler
    private let geocodeType: CLGeocoderOperationType


    public init(geocodeType: CLGeocoderOperationType, completionHandler: CLGeocodeCompletionHandler) {
        self.geocoder = CLGeocoder()
        self.geocodeType = geocodeType
        self.completionHandler = completionHandler
        super.init()
    }

    convenience public init(location: CLLocation, completionHandler: CLGeocodeCompletionHandler) {
        self.init(geocodeType: .ReverseGeocodeLocation(location), completionHandler: completionHandler)
    }

    convenience public init(locationProvider: LocationProvider, completionHandler: CLGeocodeCompletionHandler) {
        self.init(geocodeType: .ReverseGeocodeLocationProvider(locationProvider), completionHandler: completionHandler)
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
        let finishHandler: CLGeocodeCompletionHandler = { (locations, error) in
            let finishOperation = NSBlockOperation() {
                self.placemark = locations?.first
                self.completionHandler(locations, error)
                self.finish()
            }
            self.produceOperation(finishOperation)
        }

        switch geocodeType {
        case .ReverseGeocodeLocation(let location):
            geocoder.reverseGeocodeLocation(location, completionHandler: finishHandler)
        case .ReverseGeocodeLocationProvider(let locationProvider):
            if let location = locationProvider.location {
                geocoder.reverseGeocodeLocation(location, completionHandler: finishHandler)
            } else {
                let error = NSError(code: .ExecutionFailed, userInfo: [
                    "LocationProvider": "No location provided."
                    ])

                self.cancelWithError(error)
            }
        case .ForwardGeocodeAddressDictionary(let addressDictionary):
            geocoder.geocodeAddressDictionary(addressDictionary, completionHandler: finishHandler)
        case .ForwardGeocodeAddressString(let addressString):
            geocoder.geocodeAddressString(addressString, completionHandler: finishHandler)
        case .ForwardGeocodeAddressStringInRegion(let addressString, let addressRegion):
            geocoder.geocodeAddressString(addressString, inRegion: addressRegion, completionHandler: finishHandler)
        }
    }

    override public func cancel() {
        geocoder.cancelGeocode()
        super.cancel()
    }
}
