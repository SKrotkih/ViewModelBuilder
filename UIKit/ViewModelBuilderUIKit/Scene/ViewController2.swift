import UIKit
import Combine
import ViewModel

/// ViewController2 uses the @ViewModelBuilder
class ViewController2: UIViewController {
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var errorMessage: UILabel!

    private var disposableBag = Set<AnyCancellable>()
    private var viewModel: ViewModel!
    
    override func viewDidLoad() {
        viewModel = buildViewModel()
        viewModel.downloadImage(url: Mock.backGroundImageURL)
    }

    private func buildViewModel() -> ViewModel {
        ViewModel {
            // @ViewModelBuilder uses ViewModelEvents
            // BackgroundImage is a ViewModelEvent
            BackgroundImage()
                // ViewModelEvent modifiers
                .onDownloaded { [weak self] image in
                    self?.activityIndicator.stopAnimating()
                    self?.backgroundImageView.image = image
                }
                .isDowloading {[weak self] in
                    self?.activityIndicator.startAnimating()
                }
                .onError { [weak self] text in
                    self?.errorMessage.text = text
                }
        }
    }
}
