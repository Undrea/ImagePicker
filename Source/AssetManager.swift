import Foundation
import UIKit
import Photos

open class AssetManager {

  public static func getImage(_ name: String) -> UIImage {
    let traitCollection = UITraitCollection(displayScale: 3)
    var bundle = Bundle(for: AssetManager.self)

    if let resource = bundle.resourcePath, let resourceBundle = Bundle(path: resource + "/ImagePicker.bundle") {
      bundle = resourceBundle
    }

    return UIImage(named: name, in: bundle, compatibleWith: traitCollection) ?? UIImage()
  }

  public static func fetch(withConfiguration configuration: Configuration, _ completion: @escaping (_ assets: PhotoAssets) -> Void) {
    guard PHPhotoLibrary.authorizationStatus() == .authorized else { return }

    DispatchQueue.global(qos: .userInitiated).async {
      // Get oldest first
      let fetchOptions = PHFetchOptions()
      fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

      let fetchResult = configuration.allowVideoSelection
        ? PHAsset.fetchAssets(with: fetchOptions)
        : PHAsset.fetchAssets(with: .image, options: fetchOptions)

      if fetchResult.count > 0 {
        DispatchQueue.main.async {
          NSLog("End fetch, \(fetchResult.count) results")
          completion(PhotoAssets(withResults: fetchResult))
        }
      }
    }
  }

  public static func resolveAsset(_ asset: PHAsset, size: CGSize = CGSize(width: 720, height: 1280), completion: @escaping (_ image: UIImage?) -> Void) {
    let imageManager = PHImageManager.default()
    let requestOptions = PHImageRequestOptions()
    requestOptions.deliveryMode = .highQualityFormat
    requestOptions.isNetworkAccessAllowed = true
    requestOptions.isSynchronous = false
    
    imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: requestOptions) { image, info in
      if let info = info, info["PHImageFileUTIKey"] == nil {
        DispatchQueue.main.async(execute: {
          completion(image)
        })
      }
    }
  }

  public static func resolveAssets(_ assets: [PHAsset], size: CGSize = CGSize(width: 720, height: 1280), completion: @escaping ([Data]) -> Void) {
    let imageManager = PHImageManager.default()
    let requestOptions = PHImageRequestOptions()
    requestOptions.deliveryMode = .highQualityFormat
    requestOptions.isNetworkAccessAllowed = true
    requestOptions.isSynchronous = false
    
    let group = DispatchGroup()
    var imageDataArr: [Data] = []

    for asset in assets {
      group.enter()
      imageManager.requestImageData(for: asset, options: requestOptions, resultHandler: { (imageData, dataUTI, orientation, infoDict) in
        if let imageData = imageData {
          imageDataArr.append(imageData)
        }
        group.leave()
      })
    }

    group.notify(queue: .main) {
      // All the imageData elements have been 'downloaded'
      completion(imageDataArr)
    }
  }
}
