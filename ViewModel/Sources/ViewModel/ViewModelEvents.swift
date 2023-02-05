import UIKit
import Combine

public protocol ViewModelEvent {
    func perform(at viewModel: ViewModel)
}

public class BackgroundImage: ViewModelEvent {
    typealias DownloadedClosure = (UIImage?) -> Void
    typealias IsDowloadingClosure = () -> Void
    typealias ErrorClosure = (String?) -> Void
    
    private var disposableBag = Set<AnyCancellable>()
    private var onDownloaded: DownloadedClosure?
    private var isDowloading: IsDowloadingClosure?
    private var onError: ErrorClosure?
    
    public init() {}
    
    /// Called by the builder
    /// - Parameter viewModel: ViewModel
    public func perform(at viewModel: ViewModel) {
        self.isDowloading?()
        if onDownloaded != nil {
            viewModel.$image
                .receive(on: RunLoop.main)
                .sink { image in
                    self.onDownloaded?(image)
                }.store(in: &disposableBag)
        }
        if onError != nil {
            viewModel.$networkError
                .receive(on: RunLoop.main)
                .sink { errorMessage in
                    self.onError?(errorMessage)
                }.store(in: &disposableBag)
        }
    }

    // Modifiers
    @discardableResult public func onDownloaded(_ closure: @escaping (UIImage?) -> Void) -> BackgroundImage {
        onDownloaded = closure
        return self
    }
    
    @discardableResult public func isDowloading(_ closure: @escaping () -> Void) -> BackgroundImage {
        isDowloading = closure
        return self
    }

    @discardableResult public func onError(_ closure: @escaping (String?) -> Void) -> BackgroundImage {
        onError = closure
        return self
    }
}
