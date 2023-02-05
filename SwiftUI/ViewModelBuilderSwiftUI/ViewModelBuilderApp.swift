import SwiftUI
import ViewModel

@main
struct ResultBuilderApp: App {
    let viewModel = ViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}
