import UIKit
import Combine
import ViewModel

class ViewController: UIViewController {
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var errorMessage: UILabel!
    
    private var disposableBag = Set<AnyCancellable>()
    private let viewModel: ViewModel = ViewModel()
    
    override func viewDidLoad() {
        subscrbeOnEvents()
        viewModel.downloadImage(url: Mock.backGroundImageURL)
    }

    private func subscrbeOnEvents() {
        viewModel.$isDownloadingData
            .receive(on: RunLoop.main)
            .sink { [weak self] inProcess in
                if inProcess {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                }
            }.store(in: &disposableBag)
        viewModel.$image
            .receive(on: RunLoop.main)
            .sink { [weak self] image in
                self?.backgroundImageView.image = image
            }.store(in: &disposableBag)
        viewModel.$networkError
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                self?.errorMessage.text = text
            }.store(in: &disposableBag)
    }
}
