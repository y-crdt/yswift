import Foundation

func main() {
    let doc = Doc()
    let text = doc.getText(name: "some_text")
    let txn = doc.transact()
    text.append(tx: txn, text: "hello, world!")
    txn.free()
}
