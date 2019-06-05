//
//  Date+isoTime.swift
//  ImagePicker
//
//  Created by Isabella on 2017-04-11.
//  Copyright © 2017 Hyper Interaktiv AS. All rights reserved.
//

import Foundation

extension Date {
  func isoTime() -> String {
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone(abbreviation: "UTC")
    formatter.dateFormat = "HH:mm:ss.SSSSSS"
    return formatter.string(from: self)
  }
}
