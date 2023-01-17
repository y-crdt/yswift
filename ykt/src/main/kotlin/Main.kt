import uniffi.ykt.Doc

fun main() {
  val doc = Doc()
  val text = doc.getText("my_text")

  val tx = doc.transact()

  text.append(tx, "Hello, World!")
  println(text.getString(tx))

  tx.free()
}
