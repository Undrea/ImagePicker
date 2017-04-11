//
//  CLLocation+gpsMetadata.swift
//  ImagePicker
//
//  Created by Isabella on 2017-04-11.
//  Copyright © 2017 Hyper Interaktiv AS. All rights reserved.
//

import CoreLocation
import ImageIO

extension CLLocation {
  func gpsMetadata(heading: CLHeading? = nil) -> Dictionary<AnyHashable, Any> {
    let altitudeRef = Int(self.altitude < 0.0 ? 1 : 0)
    let latitudeRef = self.coordinate.latitude < 0.0 ? "S" : "N"
    let longitudeRef = self.coordinate.longitude < 0.0 ? "W" : "E"
    
    var gpsMetadata: Dictionary<AnyHashable, Any> = [
      kCGImagePropertyGPSLatitude as String: abs(self.coordinate.latitude),
      kCGImagePropertyGPSLongitude as String: abs(self.coordinate.longitude),
      kCGImagePropertyGPSLatitudeRef as String: latitudeRef,
      kCGImagePropertyGPSLongitudeRef as String: longitudeRef,
      kCGImagePropertyGPSAltitude as String: Int(abs(self.altitude)),
      kCGImagePropertyGPSAltitudeRef as String: altitudeRef,
      kCGImagePropertyGPSTimeStamp as String: self.timestamp.isoTime(),
      kCGImagePropertyGPSDateStamp as String: self.timestamp.isoDate(),
      kCGImagePropertyGPSVersion as String: "2.2.0.0"
    ]
    
    if let heading = heading {
      gpsMetadata[kCGImagePropertyGPSImgDirection as String] = heading.trueHeading
      gpsMetadata[kCGImagePropertyGPSImgDirectionRef as String] = "T"
    }
    
    return gpsMetadata
  }
}
