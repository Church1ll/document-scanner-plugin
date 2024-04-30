import UIKit
import AVFoundation

class CameraViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, AVCapturePhotoCaptureDelegate {
    
    var imagePicker: UIImagePickerController!
    var capturedImages: [UIImage] = []
    var completionHandler: (([String]) -> Void)?
    var collectionView: UICollectionView!
    var overlayView: UIView!
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var photoOutput: AVCapturePhotoOutput!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground;
        view.frame = UIScreen.main.bounds
//        setupImagePicker()
        setupCaptureSession()
        setupCollectionView()
        setupButtons()
    }

    private func setupImagePicker() {
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        imagePicker.showsCameraControls = false // We are using custom controls
        
//        configureOverlay()
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

    
//    private func configureOverlay() {
//        overlayView = UIView(frame: imagePicker.view.bounds)
//        overlayView.backgroundColor = .clear
//
//        // Increase the padding height to move the camera preview as low as before
//        let paddingHeight: CGFloat = 100 // Increase padding to push the camera view down
//        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: overlayView.bounds.width, height: paddingHeight))
//        paddingView.backgroundColor = .black
//        overlayView.addSubview(paddingView)
//
//        // "Done" button at the top of the overlay
//        let finishButton = UIButton(type: .system)
//        finishButton.frame = CGRect(x: overlayView.bounds.width - 100 - 20,
//                                    y: 20, // Positioned at the top, above the camera preview
//                                    width: 100,
//                                    height: 50)
//        finishButton.setTitle("Done", for: .normal)
//        finishButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
//        finishButton.tintColor = .systemBlue
//        finishButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
//        overlayView.addSubview(finishButton)
//
//        // "Shutter" button adjusted higher relative to the bottom of the view
//        let shutterButtonSize: CGFloat = 70
//        let shutterButton = UIButton(type: .system)
//        shutterButton.frame = CGRect(x: (overlayView.bounds.width - shutterButtonSize) / 2,
//                                     y: overlayView.bounds.height - shutterButtonSize - 30, // Adjusted for ergonomic reach
//                                     width: shutterButtonSize,
//                                     height: shutterButtonSize)
//        shutterButton.setTitle("Take", for: .normal)
//        shutterButton.titleLabel?.font = .systemFont(ofSize: 14)
//        shutterButton.tintColor = .white
//        shutterButton.layer.cornerRadius = shutterButtonSize / 2
//        shutterButton.backgroundColor = UIColor(white: 1, alpha: 0.5)
//        shutterButton.layer.borderWidth = 2
//        shutterButton.layer.borderColor = UIColor.white.cgColor
//        shutterButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
//        overlayView.addSubview(shutterButton)
//
//        imagePicker.cameraOverlayView = overlayView
//    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait // This locks the view controller to portrait mode
    }
    
    override var shouldAutorotate: Bool {
        return false
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
        
            let doneButton = UIButton(type: .system)
            doneButton.frame = CGRect(x: view.bounds.width - 100, y: 0, width: 100, height: 50)
            doneButton.setTitle("Done", for: .normal)
            doneButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
            doneButton.tintColor = .systemBlue
            doneButton.addTarget(self, action: #selector(finishCapturing), for: .touchUpInside)
            view.addSubview(doneButton)

            let shutterButton = UIButton(type: .system)
            shutterButton.frame = CGRect(x: (view.bounds.width - 70) / 2, y: collectionView.frame.maxY + 5, width: 70, height: 70)
            shutterButton.setTitle("Take", for: .normal)
            shutterButton.titleLabel?.font = .systemFont(ofSize: 14)
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
        let deleteButton = UIButton(type: .system)
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

//    func presentCamera() {
//        imagePicker.modalPresentationStyle = .fullScreen
//        present(imagePicker, animated: true, completion: nil)
//    }

//    @objc func capturePhoto() {
//        // Use the image picker to capture a photo
//        imagePicker.takePicture()
//    }
    
    func correctImageOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return normalizedImage
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else { return }
        let correctedImage = correctImageOrientation(image)
//        capturedImages.append(correctedImage)

        // Update the UI without dismissing the UIImagePickerController
        showReviewForImage(correctedImage, on: picker)
//        collectionView.reloadData()
    }

    private func showReviewForImage(_ image: UIImage, on picker: UIImagePickerController) {
        let reviewVC = UIViewController()
        reviewVC.view.backgroundColor = .black
        
        let imageView = UIImageView(image: image)
        imageView.frame = reviewVC.view.bounds
        imageView.contentMode = .scaleAspectFit
        reviewVC.view.addSubview(imageView)

        let useButton = UIButton(type: .system)
        useButton.frame = CGRect(x: 20, y: reviewVC.view.bounds.height - 80, width: 100, height: 50)
        useButton.setTitle("Use Photo", for: .normal)
        useButton.titleLabel?.font = .systemFont(ofSize: 18)
        useButton.tintColor = .systemBlue
        useButton.addTarget(self, action: #selector(usePhoto), for: .touchUpInside)
        reviewVC.view.addSubview(useButton)

        let retakeButton = UIButton(type: .system)
        retakeButton.frame = CGRect(x: 200, y: reviewVC.view.bounds.height - 80, width: 100, height: 50)
        retakeButton.setTitle("Retake", for: .normal)
        retakeButton.titleLabel?.font = .systemFont(ofSize: 18)
        retakeButton.tintColor = .systemRed
        retakeButton.addTarget(self, action: #selector(retakePhoto), for: .touchUpInside)
        reviewVC.view.addSubview(retakeButton)

        picker.pushViewController(reviewVC, animated: true)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        }
        
        // Extract image data from the photo object
        guard let imageData = photo.fileDataRepresentation() else {
            print("Could not obtain image data from photo object")
            return
        }
        
        // Convert the image data to a UIImage and append it to your capturedImages array
        if let image = UIImage(data: imageData) {
            capturedImages.append(image)
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }


    @objc func usePhoto() {
        if let topVC = imagePicker.topViewController,
           let imageView = topVC.view.subviews.compactMap({ $0 as? UIImageView }).first,
           let image = imageView.image {
            capturedImages.append(image)
            collectionView.reloadData()
            imagePicker.popViewController(animated: true)
        }
    }

    @objc func retakePhoto() {
        imagePicker.popViewController(animated: true)
    }

    @objc func finishCapturing() {
        let base64Images = capturedImages.map { image -> String? in
                let correctedImage = correctImageOrientation(image)
                guard let imageData = correctedImage.jpegData(compressionQuality: 0.8) else { return nil }
                return imageData.base64EncodedString()
            }
            completionHandler?(base64Images.compactMap { $0 })
            dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
