import SwiftUI
import ViewModel

@main
struct ResultBuilderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: ViewModel())
        }
    }
}
