import Foundation

protocol NftSendConfirmViewModelFactoryProtocol {
    func buildViewModel(nft: NFT) -> NftSendConfirmViewModel
}

final class NftSendConfirmViewModelFactory: NftSendConfirmViewModelFactoryProtocol {
    func buildViewModel(nft: NFT) -> NftSendConfirmViewModel {
        var imageViewModel: ImageViewModelProtocol?

        if let image = nft.metadata?.image, let url = URL(string: image) {
            imageViewModel = RemoteImageViewModel(url: url)
        }

        return NftSendConfirmViewModel(
            nftImage: imageViewModel,
            collectionName: nft.tokenName,
            showWarning: false
        )
    }
}