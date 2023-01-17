# ykt

> Kotlin bindings for yrs.

## Getting started

```kotlin
import uniffi.ykt.Doc

fun main() {
  val doc = Doc()
  val text = doc.getText("my_text")

  val tx = doc.transact()

  text.append(tx, "Hello, World!")
  println(text.getString(tx))

  tx.free()
}
```

## Build instructions

### Scaffold Rust Code from UDL file

```bash
uniffi-bindgen scaffolding src/ykt.udl
```

### Build Rust Code

```bash
cargo build
```

### Generate Kotlin Code

```bash
uniffi-bindgen generate src/ykt.udl --language kotlin --no-format --out-dir src/main/kotlin
```
