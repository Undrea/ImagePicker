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
    let f = DateFormatter()
    f.timeZone = TimeZone(abbreviation: "UTC")
    f.dateFormat = "yyyy:MM:dd"
    return f.string(from: self)
  }
}
