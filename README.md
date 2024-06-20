# RT-ImageCache

A Swift package for efficient image caching. Uses modern concurrency principles.

## Installation

To add `RT-ImageCache` to your Xcode project, add the following to your `Package.swift` file:

```swift
// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "YourProject",
    dependencies: [
        .package(url: "https://github.com/ronitios96/RT-ImageCache.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "YourProject",
            dependencies: ["RT-ImageCache"]
        )
    ]
)

```markdown
## Usage

Here’s a basic example of how to use `RT-ImageCache`:

```swift
import RT-ImageCache

guard let shared = ImageCacheUtility.shared else { return }
    do {
        let contentFound = try await shared.image(for: yourImageURL)
        content = (Image(uiImage: contentFound.image), contentFound.msg) 
    } catch {
        print("Some Error : \(error.localizedDescription)")
    }

```markdown
## Contributing

Contributions are welcome! Please submit pull requests and open issues as needed.

## License

`RT-ImageCache` is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
