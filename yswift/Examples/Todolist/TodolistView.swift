import SwiftUI
import Combine
import YSwift

struct TodoItem: Codable, Hashable, Identifiable {
    var title: String
    var isCompleted: Bool = false
    
    var id: Int {
        hashValue
    }
}

struct TodolistView: View {
    @ObservedObject var viewModel: TodolistViewModel
    @State private var text = ""
    
    var body: some View {
        VStack {
            HStack {
                TextField("New task", text: $text, onCommit:  {
                    viewModel.addItem(.init(title: text))
                    text = ""
                }).padding()
            }
            if let connState = viewModel.connectionState {
                HStack(spacing: 8) {
                    Text(connState.rawValue.uppercased())
                        .font(.system(size: 14, weight: .thin, design: .monospaced))
                    Spacer()
                    if connState == .notConnected {
                        Button("Connect") {
                            viewModel.connect()
                        }
                        .tint(.green)
                    } else {
                        Button("Disconnect", role: .destructive) {
                            viewModel.disconnect()
                        }
                    }
                    
                }
                .padding()
            }
            List {
                Section(header: Text("To Do")) {
                    ForEach(viewModel.items.filter { !$0.isCompleted }) { item in
                        Text(item.title)
                            .swipeActions {
                                Button("Done") {
                                    viewModel.toggleItem(item)
                                }
                                .tint(.green)
                            }
                    }
                }
                Section(header: Text("Done")) {
                    ForEach(viewModel.items.filter { $0.isCompleted }) { item in
                        Text(item.title)
                            .strikethrough()
                            .opacity(0.5)
                            .swipeActions {
                                Button("Undo") {
                                    viewModel.toggleItem(item)
                                }
                                .tint(.blue)
                                Button("Delete", role: .destructive) {
                                    viewModel.removeItem(item)
                                }
                            }
                    }
                }
            }
        }
    }
}

