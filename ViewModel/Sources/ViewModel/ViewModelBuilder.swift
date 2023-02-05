import Foundation

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
