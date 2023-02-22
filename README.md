# Result Builder in Swift for MVVM Pattern 

The letter first published at the [Medium.com](https://medium.com/@sergeykrotkih/result-builder-in-swift-for-mvvm-pattern-772dcb0cdb48). Follow me for more content like this and don't forget to drop a clap if you like it :)
Another publish at the [CodeProject](https://www.codeproject.com/Tips/5353219/Result-Builder-in-Swift-for-MVVM-Pattern)
My [Linkedin profile](https://www.linkedin.com/in/serhii-krotkykh-2746a420/)

## Introduction ##

As known, SwiftUI uses *@viewBuilder* for building UI via views. *@viewBuilder* is an implementation of the
Result builder. You can find out more about it by reading Result builder proposal at the [Swift Evolution proposals website](https://github.com/apple/swift-evolution/blob/main/proposals/0289-result-builders.md). 
There are other examples of using Result builder [here](https://github.com/carson-katri/awesome-result-builders).
Let me give you another example of using Result builder for the MVVM pattern.

## Traditional MVVM implementation

```swift
public class ViewModel: ViewModelDowladable {
    @Published public var isDownloadingData = false
    @Published public var image: UIImage?
    @Published public var networkError: String?

    public init() { }
    
    enum NetworkError: Error {
        case invalidImageUrl
        case invalidServerResponse
        case unsupportedImage
    }
    
    public func downloadImage(url: String) {
        Task { @MainActor in
            isDownloadingData = true
            do {
                let im = try await fetchImage(url: URL(string: url))
                image = im
                networkError = nil
            } catch {
                image = nil
                networkError = error.localizedDescription
            }
            isDownloadingData = false
        }
    }
    
    private func fetchImage(url: URL?) async throws -> UIImage {
        guard let url else {
            throw NetworkError.invalidImageUrl
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidServerResponse
        }
        guard let image = UIImage(data: data) else {
            throw NetworkError.unsupportedImage
        }
        return image
    }
}
```

The *ViewModel* class is a view model example. As you can see, it responds by fetching images by URL and informing clients about the results of the operation. So it has three observable events and one shared method to download images for URLs. The client of the view model can start downloading when it will be ready and waiting for results. Let's implement two kinds of clients. The first one is a SwiftUI *contentView*:

```swift
struct ContentView<ViewModel: ViewModelDowladable>: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        ZStack {
            if viewModel.image == nil {
                Image(systemName: Mock.placeholderImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(uiImage: viewModel.image!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            VStack {
                Spacer()
                if viewModel.isDownloadingData {
                    Text("Downloading...")
                        .foregroundColor(.green)
                        .font(.title)
                    Spacer()
                }
                if let text = viewModel.networkError {
                    Text(text)
                        .foregroundColor(.red)
                        .font(.title)
                }
            }
            .padding()
        } .onAppear() {
            viewModel.downloadImage(url: Mock.backGroundImageURL)
        }
    }
}
```
There is nothing special so far.
And another kind of client. In this case, it's UIKit *UIViewController*.

```swift
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
```
The *viewController* owns *viewModel*, subscribes to the events, and updates the UI according to the downloading results. But as you can see, the client 'knows' about the view model's structure and details of implementation. Is there a way to hide that? The client must depend on abstractions only. Let's use a result builder for that.

## Creating a custom Result Builder

```swift
public protocol ViewModelEvent {
    func perform(at viewModel: ViewModel)
}

@resultBuilder
public struct ViewModelBuilder {
    public static func buildBlock(_ components: ViewModelEvent...) -> [ViewModelEvent] {
        components
    }
}

public extension ViewModel {
    convenience init(@ViewModelBuilder _ builder: () -> [ViewModelEvent]) {
        self.init()
        let components = builder()
        for component in components {
            component.perform(at: self)
        }
    }
}
```
*@ViewModelBuilder* gives us the ability to rewrite the *ViewController* with a new domain-specific language (DSL):

```swift
class ViewController: UIViewController {
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
            // BackgroundImage is the ViewModelEvent
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
```
In this case, the viewController depends on some abstract view model events 'domain statements' BackgroundImage, IsDownloadingData, and NetworkError.
They belong to the ViewModel. 

```swift
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
```
That's it! You can find the source code of the *@ViewModelBuilder* [here](https://github.com/SKrotkih/mix/tree/main/Source/ViewModelBuilder).
Learn more about the *@ViewModelBuilder* here(https://github.com/SKrotkih/TwilioCallKitQuickstart) and here(https://github.com/SKrotkih/twilio-voice-ios-adapter).

Thank you!

## Requirements

- Xcode 14+
- Swift 5.7

## History ##

- 28th January, 2023: Initial version
- 1 February 2023: Modifiers added
