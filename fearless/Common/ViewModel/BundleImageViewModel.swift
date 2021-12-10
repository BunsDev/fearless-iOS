import UIKit

final class BundleImageViewModel: NSObject {
    let image: UIImage?

    init(image: UIImage?) {
        self.image = image
    }
}

extension BundleImageViewModel: ImageViewModelProtocol {
    func loadImage(on imageView: UIImageView, targetSize _: CGSize, animated _: Bool) {
        imageView.image = image
    }

    func cancel(on imageView: UIImageView) {
        imageView.image = nil
    }
}
