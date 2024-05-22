# SwiftImageHash

SwiftImageHash is a Swift package that provides tools for computing perceptual hashes of images. This allows you to compare images based on their visual content, which can be useful for verifying if two images are visually identical.

## Features

- Compute perceptual hashes (pHash) for `UIImage` objects.
- Calculate the Hamming distance between two perceptual hashes to determine image similarity.

## Requirements

- iOS 16.0+
- Swift 5.3+
- Xcode 12.0+

## Installation

### Swift Package Manager

You can install `SwiftImageHash` using the Swift Package Manager by adding the following dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/TokyoWolFrog/swiftimagehash.git", from: "0.1.1")
]
```

Then, simply add SwiftImageHash to your target dependencies:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["SwiftImageHash"]),
]
```

## Usage

Here is how you can use SwiftImageHash to compute a perceptual hash of an image and compare it with another image:

```swift
import UIKit
import SwiftImageHash

let image1: UIImage = // Your first image
let image2: UIImage = // Your second image

// Compute perceptual hashes
if let hash1 = SwiftImageHash.phash(image: image1),
   let hash2 = SwiftImageHash.phash(image: image2) {
    print("pHash of image1: \(hash1)")
    print("pHash of image2: \(hash2)")

    // Calculate Hamming distance
    if let distance = SwiftImageHash.distanceBetween(hash1, hash2) {
        print("Hamming Distance: \(distance)")
    } else {
        print("Error calculating Hamming distance.")
    }
} else {
    print("Error computing perceptual hashes.")
}
```
