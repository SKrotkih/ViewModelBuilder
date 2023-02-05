import SwiftUI
import ViewModel

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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: ViewModel())
    }
}
