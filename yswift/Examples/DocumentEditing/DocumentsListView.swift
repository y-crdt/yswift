import Combine
import MultipeerConnectivity
import SwiftUI
import YSwift

struct DocumentsListView: View {
    @ObservedObject var connectionManager: ConnectionManager

    var body: some View {
        List {
            Section("Documents") {
                ForEach(connectionManager.peers, id: \.displayName) { peer in
                    Text(peer.displayName)
                        .onTapGesture {
                            connectionManager.invitePeer(peer)
                        }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}
