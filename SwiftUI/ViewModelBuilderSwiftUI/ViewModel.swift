import UIKit
import Combine

class ViewModel: ObservableObject {
    @Published public var isDownloadingData = false
    @Published public var image: UIImage?
    @Published public var networkError: String?

    enum NetworkError: Error {
        case invalidImageUrl
        case invalidServerResponse
        case unsupportedImage
    }
    
    func downloadPhoto(url: String) {
        Task { @MainActor in
            isDownloadingData = true
            do {
                image = try await fetchPhoto(url: URL(string: url))
                networkError = nil
            } catch {
                image = nil
                networkError = error.localizedDescription
            }
            isDownloadingData = false
        }
    }
    
    private func fetchPhoto(url: URL?) async throws -> UIImage {
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
