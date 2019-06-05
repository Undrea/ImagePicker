import Foundation
import AVFoundation
import PhotosUI

protocol CameraManDelegate: class {
  func cameraManNotAvailable(_ cameraMan: CameraMan)
  func cameraManDidStart(_ cameraMan: CameraMan)
  func cameraMan(_ cameraMan: CameraMan, didChangeInput input: AVCaptureDeviceInput)
}

class CameraMan {
  weak var delegate: CameraManDelegate?

  let session = AVCaptureSession()
  let queue = DispatchQueue(label: "no.hyper.ImagePicker.Camera.SessionQueue")

  var backCamera: AVCaptureDeviceInput?
  var frontCamera: AVCaptureDeviceInput?
  var stillImageOutput: AVCaptureStillImageOutput?
  var startOnFrontCamera: Bool = false

  var isCameraAuthorized: Bool {
    return AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == .authorized
  }
  
  deinit {
    stop()
  }

  // MARK: - Setup

  func setup(startOnFrontCamera: Bool = false, shouldShowPermissionAlerts: Bool = true) {
    self.startOnFrontCamera = startOnFrontCamera
    
    if shouldShowPermissionAlerts {
      checkPermission() // Will start the camera if authorized or notify the delegate if denied
    } else if isCameraAuthorized {
      start()
    } else {
      delegate?.cameraManNotAvailable(self)
    }
  }

  func setupDevices() {
    // Input
    AVCaptureDevice
    .devices().flatMap {
      return $0 as? AVCaptureDevice
    }.filter {
      return $0.hasMediaType(AVMediaType.video)
    }.forEach {
      switch $0.position {
      case .front:
        self.frontCamera = try? AVCaptureDeviceInput(device: $0)
      case .back:
        self.backCamera = try? AVCaptureDeviceInput(device: $0)
      default:
        break
      }
    }

    // Output
    stillImageOutput = AVCaptureStillImageOutput()
    stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
  }

  func addInput(_ input: AVCaptureDeviceInput) {
    configurePreset(input)

    if session.canAddInput(input) {
      session.addInput(input)

      DispatchQueue.main.async {
        self.delegate?.cameraMan(self, didChangeInput: input)
      }
    }
  }

  // MARK: - Permission

  func checkPermission() {
    let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)

    switch status {
    case .authorized:
      start()
    case .notDetermined:
      requestPermission()
    default:
      delegate?.cameraManNotAvailable(self)
    }
  }

  func requestPermission() {
    AVCaptureDevice.requestAccess(for: AVMediaType.video) { granted in
      DispatchQueue.main.async {
        if granted {
          self.start()
        } else {
          self.delegate?.cameraManNotAvailable(self)
        }
      }
    }
  }

  // MARK: - Session

  var currentInput: AVCaptureDeviceInput? {
    return session.inputs.first as? AVCaptureDeviceInput
  }

  fileprivate func start() {
    // Devices
    setupDevices()

    guard let input = (self.startOnFrontCamera) ? frontCamera ?? backCamera : backCamera, let output = stillImageOutput else { return }

    addInput(input)

    if session.canAddOutput(output) {
      session.addOutput(output)
    }

    queue.async {
      self.session.startRunning()

      DispatchQueue.main.async {
        self.delegate?.cameraManDidStart(self)
      }
    }
  }

  func stop() {
    self.session.stopRunning()
  }

  func switchCamera(_ completion: (() -> Void)? = nil) {
    guard let currentInput = currentInput
      else {
        completion?()
        return
    }

    queue.async {
      guard let input = (currentInput == self.backCamera) ? self.frontCamera : self.backCamera
        else {
          DispatchQueue.main.async {
            completion?()
          }
          return
      }

      self.configure {
        self.session.removeInput(currentInput)
        self.addInput(input)
      }

      DispatchQueue.main.async {
        completion?()
      }
    }
  }

  func takePhoto(_ previewLayer: AVCaptureVideoPreviewLayer, location: CLLocation?, completion: (() -> Void)? = nil) {
    guard let connection = stillImageOutput?.connection(with: AVMediaType.video) else { return }
    
    connection.videoOrientation = Helper.videoOrientation()
    
    queue.async {
      self.stillImageOutput?.captureStillImageAsynchronously(from: connection) { buffer, error in
        guard let buffer = buffer, error == nil && CMSampleBufferIsValid(buffer) else {
          DispatchQueue.main.async {
            completion?()
          }
          return
        }
        
        // If we have a location, append the metadata to the buffer 
        // This avoids making a copy of the buffer image and duplicating, as with using source/destination. (i.e. CGImageSourceCreateWithData)
        if let location = location {
          var metaDict = CMCopyDictionaryOfAttachments(allocator: nil, target: buffer, attachmentMode: kCMAttachmentMode_ShouldPropagate) as? Dictionary<String, Any> ?? [:]
          metaDict[kCGImagePropertyGPSDictionary as String] = location.gpsMetadata()
          
          CMSetAttachments(buffer, attachments: metaDict as CFDictionary, attachmentMode: kCMAttachmentMode_ShouldPropagate)
        }
        
        guard let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer) else {
          DispatchQueue.main.async {
            completion?()
          }
          return
        }
        
        // Now save this image to the Camera Roll
        self.savePhoto(withData: imageData, completion: completion)
      }
    }
  }
  
  func savePhoto(withData data: Data, completion: (() -> Void)? = nil) {
    // Note that using the Photos API .location property on a request does NOT embed GPS metadata into the data for a file.
    PHPhotoLibrary.shared().performChanges({
      if #available(iOS 9.0, *) {
        // For iOS 9+ we can skip the temporary file step and write the image data from the buffer right to an asset
        let request = PHAssetCreationRequest.forAsset()
        request.addResource(with: PHAssetResourceType.photo, data: data, options: nil)
        request.creationDate = Date()
      } else {
        // Fallback on earlier versions; write a temporary file and then add this file to the Camera Roll using the Photos API
        let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("tempPhoto").appendingPathExtension("jpg")
        do {
          try data.write(to: tmpURL)
          
          let request = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: tmpURL)
          request?.creationDate = Date()
        } catch {
          // Error writing the data; photo is not appended to the camera roll
        }
      }
    }, completionHandler: { (isSuccess, error) in
      // FIXME Handle error case for Swift 4.2
      DispatchQueue.main.async {
        completion?()
      }
    })
  }

  func flash(_ mode: AVCaptureDevice.FlashMode) {
    guard let device = currentInput?.device, device.isFlashModeSupported(mode) else { return }

    queue.async {
      self.lock {
        device.flashMode = mode
      }
    }
  }

  func focus(_ point: CGPoint) {
    guard let device = currentInput?.device, device.isFocusModeSupported(AVCaptureDevice.FocusMode.locked) else { return }

    queue.async {
      self.lock {
        device.focusPointOfInterest = point
      }
    }
  }

  // MARK: - Lock

  func lock(_ block: () -> Void) {
    if let device = currentInput?.device, (try? device.lockForConfiguration()) != nil {
      block()
      device.unlockForConfiguration()
    }
  }

  // MARK: - Configure
  func configure(_ block: () -> Void) {
    session.beginConfiguration()
    block()
    session.commitConfiguration()
  }

  // MARK: - Preset

  func configurePreset(_ input: AVCaptureDeviceInput) {
    for asset in preferredPresets() {
      if input.device.supportsSessionPreset(asset) && self.session.canSetSessionPreset(asset) {
        self.session.sessionPreset = asset
        return
      }
    }
  }

  func preferredPresets() -> [AVCaptureSession.Preset] {
    return [
      AVCaptureSession.Preset.high,
      AVCaptureSession.Preset.medium,
      AVCaptureSession.Preset.low
    ]
  }
}
