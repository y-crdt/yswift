# ``YSwift/YText``

## Topics

### Updating Text

- ``YSwift/YText/append(_:in:)``
- ``YSwift/YText/insert(_:at:in:)``
- ``YSwift/YText/insertEmbed(_:at:in:)``
- ``YSwift/YText/insertEmbedWithAttributes(_:attributes:at:in:)``
- ``YSwift/YText/insertWithAttributes(_:attributes:at:in:)``
- ``YSwift/YText/removeRange(start:length:in:)``
- ``YSwift/YText/format(at:length:attributes:in:)``

### Inspecting the Text

- ``YSwift/YText/description``
- ``YSwift/YText/length(in:)``
- ``YSwift/YText/getString(in:)``

### Comparing Text

- ``YSwift/YText/!=(_:_:)``
- ``YSwift/YText/==(_:_:)``

### Observing Text Changes

- ``YSwift/YText/observe()``
- ``YSwift/YText/observe(_:)``
- ``YSwift/YText/unobserve(_:)``
- ``YSwift/YTextChange``
- ``YSwift/YTextChange/deleted(index:)``
- ``YSwift/YTextChange/inserted(value:attributes:)``
- ``YSwift/YTextChange/retained(index:attributes:)``
