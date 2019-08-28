import UIKit

extension ImageGalleryView: UICollectionViewDataSource {

  struct CollectionView {
    static let reusableIdentifier = "imagesReusableIdentifier"
  }

  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    guard let fetchResultAssets = fetchResultAssets, fetchResultAssets.count > 0 else {
      displayNoImagesMessage(true)
      return 0
    }

    displayNoImagesMessage(fetchResultAssets.count == 0)
    return fetchResultAssets.count
  }

  public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let fetchResultAssets = fetchResultAssets,
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionView.reusableIdentifier, for: indexPath) as? ImageGalleryViewCell else {
        return UICollectionViewCell()
    }

    let indexOfLastItem = (fetchResultAssets.count - 1)
    let reverseIndex = indexOfLastItem - indexPath.row
    print(reverseIndex)

    let asset = fetchResultAssets.object(at: reverseIndex)

    AssetManager.resolveAsset(asset, size: CGSize(width: 160, height: 240)) { image in
      if let image = image {
        cell.configureCell(image)

        if (indexPath as NSIndexPath).row == 0 && self.shouldTransform {
          cell.transform = CGAffineTransform(scaleX: 0, y: 0)

          UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: UIView.AnimationOptions(), animations: {
            cell.transform = CGAffineTransform.identity
          }, completion: nil)

          self.shouldTransform = false
        }

        if self.selectedStack.containsAsset(asset) {
          cell.selectedImageView.image = AssetManager.getImage("selectedImageGallery")
          cell.selectedImageView.alpha = 1
          cell.selectedImageView.transform = CGAffineTransform.identity
        } else {
          cell.selectedImageView.image = nil
        }
        cell.duration = asset.duration
      }
    }

    return cell
  }
}
