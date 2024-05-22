# swiftimagehash

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
