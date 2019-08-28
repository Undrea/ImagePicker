//
//  PhotoAssets.swift
//  ImagePicker-iOS
//
//  Created by Isabella Hugel on 2019-08-28.
//  Copyright © 2019 Hyper Interaktiv AS. All rights reserved.
//

import Foundation
import Photos

/// A structure to assist with paginating PHAssetFetchResult<PHAsset>, as some users could have
/// thousands of images. Loading into a collectionView with a flow layout will be slow if using
/// the full data set.
public struct PhotoAssets {
  private var totalFetchResultAssets: PHFetchResult<PHAsset> // Stores ALL results from the phone
  private var currentCount: Int
  private let incrementSize = 100

  var count: Int {
    return min(currentCount, totalFetchResultAssets.count)
  }

  init(withResults: PHFetchResult<PHAsset>) {
    totalFetchResultAssets = withResults
    currentCount = min(incrementSize, totalFetchResultAssets.count)
  }

  subscript(index: Int) -> PHAsset {
    guard 0..<count ~= index else {
      preconditionFailure("Array index out of bounds")
    }

    return totalFetchResultAssets.object(at: index)
  }

  mutating func expandData() -> (start: Int, expandSize: Int)? {
    guard currentCount < totalFetchResultAssets.count else {
      return nil
    }

    let oldCount = self.currentCount // Index 0 of new range
    self.currentCount += min(incrementSize, totalFetchResultAssets.count - currentCount) // Don't increase more than max array size
    let expandSize = count - oldCount

    return (start: oldCount, expandSize: expandSize)
  }

  var last: PHAsset? {
    return totalFetchResultAssets.object(at: count - 1)
  }
}
