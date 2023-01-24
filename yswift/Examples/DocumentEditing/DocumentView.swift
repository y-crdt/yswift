import SwiftUI

struct DocumentView: View {
    @ObservedObject var viewModel: DocumentViewModel
    
    var body: some View {
        TextEditor(text: $viewModel.text)
            .padding()
            .onChange(of: viewModel.text) { newValue in
            }
    }
}
