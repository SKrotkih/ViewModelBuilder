import UIKit
import Combine

public protocol ViewModelDowladable: ObservableObject {
    var isDownloadingData: Bool { get set}
    var image: UIImage? { get set }
    var networkError: String? { get set }
    func downloadImage(url: String)
}

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
