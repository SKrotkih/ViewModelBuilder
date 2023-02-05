import SwiftUI
import ViewModel

@main
struct ResultBuilderApp: App {
    @StateObject var viewModel = ViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}
