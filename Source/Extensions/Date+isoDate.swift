//
//  Date+isoDate.swift
//  ImagePicker
//
//  Created by Isabella on 2017-04-11.
//  Copyright © 2017 Hyper Interaktiv AS. All rights reserved.
//

import Foundation

extension Date {
  func isoDate() -> String {
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone(abbreviation: "UTC")
    formatter.dateFormat = "yyyy:MM:dd"
    return formatter.string(from: self)
  }
}
