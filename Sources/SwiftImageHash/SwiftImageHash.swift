// https://www.hackerfactor.com/blog/index.php?/archives/432-Looks-Like-It.html
import Foundation
import UIKit

/// `SwiftImageHash` provides functionality to compute perceptual hashes of images and to compare these hashes.
///
/// Perceptual hashing allows you to generate a fingerprint of an image based on its visual content.
public struct SwiftImageHash {
    /// Initializes a new instance of `SwiftImageHash`.
    public init() {}

    /// Computes the perceptual hash (pHash) of an image.
    ///
    /// This method first converts the image to grayscale and resizes it. It then applies a 2D Discrete Cosine Transform (DCT) to the resulting image buffer. The pHash is generated based on the DCT coefficients.
    ///
    /// - Parameter image: The `UIImage` instance for which to compute the pHash.
    /// - Returns: A `String` representing the pHash of the image, or `nil` if the image could not be processed.
    public static func phash(image: UIImage) -> String? {
        guard let imageBuf = grayscaleAndResize(image: image) else {
            return nil
        }
        
        guard let dctCoefficients = apply2DDCT(to: imageBuf) else {
            return nil
        }
        
        return generatePHash(from: dctCoefficients)
    }
    
    /// Calculates the Hamming distance between two perceptual hashes.
    ///
    /// Hamming distance is the number of positions at which the corresponding symbols are different. In the context of pHashes, it measures how many bits are different between two hash values.
    ///
    /// - Parameters:
    ///   - phash1: The first pHash as a hexadecimal `String`.
    ///   - phash2: The second pHash as a hexadecimal `String`.
    /// - Returns: An `Int` representing the Hamming distance between the two hashes, or `nil` if either hash string could not be converted to a UInt64.
    public static func distanceBetween(_ phash1: String, _ phash2: String) -> Int? {
        guard let hexValue1 = hexToUInt64(phash1) else {
            return nil
        }
        
        guard let hexValue2 = hexToUInt64(phash2) else {
            return nil
        }
        
        return hammingDistanceBetween(hexValue1, hexValue2)
    }
    
    /// Generates a perceptual hash from DCT coefficients.
    /// - Parameter coefficients: The DCT coefficients.
    /// - Returns: A hexadecimal string representing the pHash.
    private static func generatePHash(from dctCoefficients: [Float]) -> String {
        let significantCoefficients = Array(dctCoefficients.dropFirst()) // Drop DC component if present
        let mean = significantCoefficients.reduce(0, +) / Float(significantCoefficients.count)
        
        let hashBits = dctCoefficients.map { $0 > mean ? 1 : 0 }
        
        var result: UInt64 = 0
        for (index, bit) in hashBits.enumerated() {
            if bit == 1 {
                result |= (1 << (63 - index))
            }
        }
        return uint64ToHex(result)
    }

}

func hammingDistanceBetween(_ num1: UInt64, _ num2: UInt64) -> Int {
    let xorResult = num1 ^ num2
    return xorResult.nonzeroBitCount
}

func uint64ToHex(_ value: UInt64) -> String {
    return String(value, radix: 16, uppercase: true)
}

func hexToUInt64(_ hexString: String) -> UInt64? {
    return UInt64(hexString, radix: 16)
}

func generateBinaryHash(from dctCoefficients: [Float]) -> String {
    let significantCoefficients = Array(dctCoefficients.dropFirst()) // Drop DC component if present
    let mean = significantCoefficients.reduce(0, +) / Float(significantCoefficients.count)
    
    let hashBits = dctCoefficients.map { $0 > mean ? "1" : "0" }
    let hashString = hashBits.joined()
    
    return hashString
}

func hammingDistance(_ str1: String, _ str2: String) -> Int? {
    // Check if both strings are of the same length
    guard str1.count == str2.count else {
        print("Strings must be of the same length")
        return nil
    }
    
    // Calculate the Hamming distance
    let distance = zip(str1, str2).filter { $0 != $1 }.count
    return distance
}

func binaryStringToHexadecimal(_ binaryString: String) -> String {
    // Split the binary string into chunks of 4
    let chunks = stride(from: 0, to: binaryString.count, by: 4).map {
        binaryString.index(binaryString.startIndex, offsetBy: $0)..<binaryString.index(binaryString.startIndex, offsetBy: min($0 + 4, binaryString.count))
    }.map {
        binaryString[$0]
    }
    
    // Convert each binary chunk to a hexadecimal string
    let hexString = chunks.map { chunk -> String in
        let number = strtol(String(chunk), nil, 2)  // Convert binary string to an integer
        return String(format: "%X", number)  // Format the number as hexadecimal
    }.joined()  // Join all hexadecimal parts into one string
    
    return hexString
}

func hexadecimalToBinaryString(_ hexString: String) -> String {
    // Map each hexadecimal character to its binary string equivalent
    let binaryString = hexString.map { hexDigit -> String in
        guard let hexValue = Int(String(hexDigit), radix: 16) else {
            fatalError("Invalid hexadecimal character found.")
        }
        let binaryDigit = String(hexValue, radix: 2)
        // Pad with leading zeros to ensure 4 bits
        return String(repeating: "0", count: 4 - binaryDigit.count) + binaryDigit
    }.joined()
    
    return binaryString
}
