import UIKit
import Photos

final class WalletScanQRWireframe: WalletScanQRWireframeProtocol {
    func presentImageGallery(
        from view: ControllerBackedProtocol?,
        delegate: ImageGalleryDelegate,
        pickerDelegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate
    ) {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch photoAuthorizationStatus {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    if newStatus == PHAuthorizationStatus.authorized {
                        self.presentGallery(from: view, delegate: delegate, pickerDelegate: pickerDelegate)
                    } else {
                        delegate.didFail(in: self, with: ImageGalleryError.accessDeniedNow)
                    }
                }
            }
        case .restricted:
            delegate.didFail(in: self, with: ImageGalleryError.accessRestricted)
        case .denied:
            delegate.didFail(in: self, with: ImageGalleryError.accessDeniedPreviously)
        default:
            presentGallery(from: view, delegate: delegate, pickerDelegate: pickerDelegate)
        }
    }

    private func presentGallery(
        from view: ControllerBackedProtocol?,
        delegate _: ImageGalleryDelegate,
        pickerDelegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate
    ) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = pickerDelegate

        view?.controller.present(
            imagePicker,
            animated: true,
            completion: nil
        )
    }

    func close(view: ControllerBackedProtocol?) {
        view?.controller.dismiss(animated: true, completion: nil)
    }
}
