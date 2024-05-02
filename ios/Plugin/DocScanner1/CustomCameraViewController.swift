import UIKit
import AVFoundation

class CameraViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, AVCapturePhotoCaptureDelegate {
    
    var capturedImages: [UIImage] = []
    var completionHandler: (([String]) -> Void)?
    var collectionView: UICollectionView!
    var overlayView: UIView!
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var photoOutput: AVCapturePhotoOutput!
    var shutterButton: UIButton!
    var doneButton: UIButton!
    var deleteButton: UIButton!
    
    var lastKnownDeviceOrientation: UIDeviceOrientation = .portrait
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.frame = UIScreen.main.bounds
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleDeviceOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)

        setupCaptureSession()
        setupCollectionView()
        setupButtons()
    }
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()

        if let videoDevice = AVCaptureDevice.default(for: .video) {
            do {
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                if captureSession.canAddInput(videoInput) {
                    captureSession.addInput(videoInput)
                }

                // Select a preset that matches the resolution you need
                captureSession.sessionPreset = .photo // You can choose another preset to better match your needs

                photoOutput = AVCapturePhotoOutput()
                if captureSession.canAddOutput(photoOutput) {
                    captureSession.addOutput(photoOutput)
                }

                captureSession.commitConfiguration()

                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer.frame = CGRect(x: 0, y: 50, width: view.bounds.width, height: view.bounds.height * 0.65) // Customized size
                previewLayer.videoGravity = .resizeAspectFill // This will fill the frame, possibly cropping
                view.layer.addSublayer(previewLayer)

                captureSession.startRunning()
            } catch {
                print("Error: \(error)")
            }
        }
    }

    private func setupCollectionView() {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            layout.itemSize = CGSize(width: 50, height: 50)
            
            collectionView = UICollectionView(frame: CGRect(x: 0, y: previewLayer.frame.maxY + 5, width: view.bounds.width, height: 60), collectionViewLayout: layout)
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.backgroundColor = .clear
            collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "ThumbnailCell")
            view.addSubview(collectionView)
        }
    
    private func setupButtons() {
        
            let cancelButton = UIButton(type: .system)
            cancelButton.frame = CGRect(x: 0, y: 0, width: 100, height: 50) // Adjust Y position as needed
            cancelButton.setTitle("Cancel", for: .normal)
            cancelButton.titleLabel?.font = .systemFont(ofSize: 18)
            cancelButton.tintColor = .systemBlue
            cancelButton.addTarget(self, action: #selector(finishCapturing), for: .touchUpInside)
            view.addSubview(cancelButton)
        
            doneButton = UIButton(type: .system)
            doneButton.frame = CGRect(x: view.bounds.width - 100, y: 0, width: 100, height: 50)
            doneButton.setTitle("Done", for: .normal)
            doneButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
            doneButton.tintColor = .systemBlue
            doneButton.addTarget(self, action: #selector(finishCapturing), for: .touchUpInside)
            view.addSubview(doneButton)

            shutterButton = UIButton(type: .system)
            shutterButton.frame = CGRect(x: (view.bounds.width - 70) / 2, y: collectionView.frame.maxY + 5, width: 70, height: 70)
//            shutterButton.setTitle("Take", for: .normal)
//            shutterButton.titleLabel?.font = .systemFont(ofSize: 14)
            shutterButton.tintColor = .white
            shutterButton.backgroundColor = UIColor(white: 1, alpha: 0.5)
            shutterButton.layer.cornerRadius = 35
            shutterButton.layer.borderWidth = 2
            shutterButton.layer.borderColor = UIColor.white.cgColor
            shutterButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
            view.addSubview(shutterButton)
        }
    
    @objc func capturePhoto() {
        let photoSettings = AVCapturePhotoSettings()
        // Setting the flash mode to auto
        photoSettings.flashMode = .auto

        // Capturing the photo with the delegate
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }

    
    @objc func deleteImage(_ sender: UIButton) {
        // Attempt to find the UIViewController that contains the sender by traversing up the responder chain
        var responder: UIResponder? = sender
        while responder != nil {
            if let viewController = responder as? UIViewController {
                // If it's the preview VC we want to dismiss, perform the actions
                if sender.tag < capturedImages.count {
                    capturedImages.remove(at: sender.tag)
                    collectionView.reloadData()
                    viewController.dismiss(animated: true, completion: nil)
                    break
                }
            }
            responder = responder?.next
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            showFullImagePreview(for: capturedImages[indexPath.row], at: indexPath.row)
        }
    
    private func showFullImagePreview(for image: UIImage, at index: Int) {
        let previewVC = UIViewController()
        previewVC.view.backgroundColor = .systemBackground
        
        // Setup the delete button at the top
        let cancelButton = UIButton(type: .system)
        cancelButton.frame = CGRect(x: 0, y: 0, width: 100, height: 50) // Adjust Y position as needed
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 18)
        cancelButton.tintColor = .systemBlue
        cancelButton.addTarget(self, action: #selector(cancelFullImagePreview(_:)), for: .touchUpInside)
        cancelButton.tag = index
        previewVC.view.addSubview(cancelButton)

        // Setup the delete button at the top
        deleteButton = UIButton(type: .system)
        deleteButton.frame = CGRect(x: view.bounds.width - 100, y: 0, width: 100, height: 50) // Adjust Y position as needed
        deleteButton.setTitle("Delete", for: .normal)
        deleteButton.titleLabel?.font = .systemFont(ofSize: 18,  weight: .medium)
        deleteButton.tintColor = .systemRed
        deleteButton.addTarget(self, action: #selector(deleteImage(_:)), for: .touchUpInside)
        deleteButton.tag = index
        previewVC.view.addSubview(deleteButton)

        // Configure the imageView to start from the bottom of the delete button
        let imageView = UIImageView(image: image)
        imageView.frame = CGRect(x: 0, y: 75, width: previewVC.view.bounds.width, height: view.bounds.height * 0.65)
        imageView.contentMode = .scaleAspectFit
        previewVC.view.addSubview(imageView)

        // Present the preview view controller
        presentFromCurrentViewController(previewVC)
    }

    @objc func cancelFullImagePreview(_ sender: UIButton) {
        // Dismiss the currently presented view controller.
        // sender is the UIButton, we need to find the UIViewController that hosts this button.
        var responder: UIResponder? = sender
        while responder != nil {
            if let viewController = responder as? UIViewController {
                viewController.dismiss(animated: true, completion: nil)
                return
            }
            responder = responder?.next
        }
    }
    
    private func presentFromCurrentViewController(_ viewControllerToPresent: UIViewController) {
        var topController: UIViewController? = self
        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }
        // Safe to present since topController is the topmost view controller
        topController?.present(viewControllerToPresent, animated: true, completion: nil)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return capturedImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThumbnailCell", for: indexPath)
        let imageView = UIImageView(image: capturedImages[indexPath.row])
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        cell.contentView.addSubview(imageView)
        imageView.frame = cell.contentView.bounds
        return cell
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            print("Could not obtain image data from photo object")
            return
        }
        
        if let image = UIImage(data: imageData) {
            let orientedImage = correctImageOrientation(image, orientation: lastKnownDeviceOrientation)
            capturedImages.append(orientedImage)
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }

    func correctImageOrientation(_ image: UIImage, orientation: UIDeviceOrientation) -> UIImage {
        var imageOrientation: UIImage.Orientation = .up
        switch orientation {
        case .portrait:
            imageOrientation = .right
        case .portraitUpsideDown:
            imageOrientation = .left
        case .landscapeLeft:
            imageOrientation = .up // assuming the camera button is on the right
        case .landscapeRight:
            imageOrientation = .down // assuming the camera button is on the right
        default:
            break
        }
        
        guard let cgImage = image.cgImage else { return image }
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: imageOrientation)
    }

    @objc func finishCapturing() {
        let base64Images = capturedImages.map { image -> String? in
//                let correctedImage = correctImageOrientation(image)
                let normalizedImage = normalizeImageOrientation(image)
                guard let imageData = normalizedImage.jpegData(compressionQuality: 0.8) else { return nil }
                return imageData.base64EncodedString()
            }
            completionHandler?(base64Images.compactMap { $0 })
            dismiss(animated: true, completion: nil)
    }
    
    func normalizeImageOrientation(_ image: UIImage) -> UIImage {
        // Check if the image has default orientation
        if image.imageOrientation == .up {
            return image
        }
        
        // Create a graphics context with the original image's dimensions and draw the image with default orientation
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return normalizedImage
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let strongSelf = self else { return }
            let orientation = UIDevice.current.orientation
            strongSelf.updateLayoutForOrientation(orientation)
        }, completion: nil)
    }
    
    @objc func handleDeviceOrientationChange() {
        let orientation = UIDevice.current.orientation
        if orientation.isFlat || !orientation.isValidInterfaceOrientation {
            return
        }
        lastKnownDeviceOrientation = orientation
    }

    func updateLayoutForOrientation(_ orientation: UIDeviceOrientation) {
        switch orientation {
        case .portrait:
            resetTransforms()
        case .landscapeRight:
            applyLandscapeTransform(clockwise: true)
        case .landscapeLeft:
            applyLandscapeTransform(clockwise: false)
        default:
            break
        }
    }

    func resetTransforms() {
        // Reset transformations and position all elements for portrait
        
        previewLayer.transform = CATransform3DIdentity
        previewLayer.frame = CGRect(x: 0, y: 50, width: view.bounds.width, height: view.bounds.height * 0.70)
        
        collectionView.transform = CGAffineTransform.identity
        collectionView.frame = CGRect(x: 0, y: previewLayer.frame.maxY + 5, width: view.bounds.width, height: 60)


        if let deleteButton = deleteButton {
            deleteButton.frame = CGRect(x: view.bounds.width - 100, y: 0, width: 100, height: 50)
        }
        doneButton.frame = CGRect(x: view.bounds.width - 100, y: 0, width: 100, height: 50)
        shutterButton.transform = CGAffineTransform.identity
        shutterButton.frame = CGRect(x: (view.bounds.width - 70) / 2, y: collectionView.frame.maxY + 5, width: 70, height: 70)
    }

    func applyLandscapeTransform(clockwise: Bool) {
        let rotation = clockwise ? CGFloat.pi / 2 : -CGFloat.pi / 2

        // Calculate the center of the preview layer before transformation
        let originalCenter = CGPoint(x: previewLayer.bounds.midX, y: previewLayer.bounds.midY)

        // Rotate the preview layer
        previewLayer.transform = CATransform3DMakeRotation(rotation, 0, 0, 1)

        // Adjust the frame of the previewLayer after rotation
        let newWidth = view.bounds.width * 0.65  // Since original height is view.bounds.width * 0.65 in portrait
        let newHeight = view.bounds.height
        previewLayer.frame = CGRect(
            x: 130,
            y: 0,
            width: newWidth,
            height: newHeight
        )

        // Adjust collectionView for landscape
        collectionView.transform = CGAffineTransform(rotationAngle: rotation)
            collectionView.frame = CGRect(
                x: 60,  // Start from the left edge
                y: 50,  // Give some space from the top
                width: 60,  // Keep width constant
                height: view.bounds.height - 60  // Height as the rotated width of previewLayer
            )
        
        if let deleteButton = deleteButton {
            deleteButton.frame = CGRect(x: view.bounds.width - 100, y: 0, width: 100, height: 50)
        }
        
        doneButton.frame = CGRect(x: view.bounds.width - 100, y: 0, width: 100, height: 50)
        shutterButton.transform = CGAffineTransform(rotationAngle: rotation)
        shutterButton.center = CGPoint(x: view.bounds.width - 85, y: view.bounds.height / 2)  // Right side


    }

}
