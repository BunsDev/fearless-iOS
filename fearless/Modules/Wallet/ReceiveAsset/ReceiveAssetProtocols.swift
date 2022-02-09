import UIKit
import SoraFoundation
import CommonWallet

protocol ReceiveAssetPresenterProtocol: AnyObject {
    func setup()
    func share(qrImage: UIImage)
    func didTapCloseButton()
    func presentAccountOptions()
}

protocol ReceiveAssetViewProtocol: ControllerBackedProtocol {
    func didReceive(viewModel: ReceiveAssetViewModel)
    func didReceive(image: UIImage)
    func didReceive(locale: Locale)
}

protocol ReceiveAssetWireframeProtocol: AlertPresentable, ErrorPresentable, SharingPresentable, AddressOptionsPresentable {
    func close(_ view: ReceiveAssetViewProtocol)
}
