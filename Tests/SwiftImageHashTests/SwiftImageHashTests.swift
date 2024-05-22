import XCTest
@testable import SwiftImageHash

final class SwiftImageHashTests: XCTestCase {
    func nottestPerformance() {
        measure {
            // Code to test
            testPhash()
        }
    }
    
    func testPhash() {
        guard let image1 = loadImageFromResource(named: "astronaut_L") else {
            XCTFail("Failed to load the image.")
            return
        }
        let phash1 = SwiftImageHash.phash(image: image1)
        print(phash1!)
        
        guard let image2 = loadImageFromResource(named: "astronaut_M") else {
            XCTFail("Failed to load the image.")
            return
        }
        let phash2 = SwiftImageHash.phash(image: image2)
        print(phash2!)
        print(SwiftImageHash.distanceBetween(phash1!, phash2!)!)
        
        guard let image3 = loadImageFromResource(named: "astronaut") else {
            XCTFail("Failed to load the image.")
            return
        }
        let phash3 = SwiftImageHash.phash(image: image3)
        print(phash3!)
        print(SwiftImageHash.distanceBetween(phash1!, phash3!)!)
        print(SwiftImageHash.distanceBetween(phash2!, phash3!)!)
        
        guard let image4 = loadImageFromResource(named: "Lenna") else {
            XCTFail("Failed to load the image.")
            return
        }
        let phash4 = SwiftImageHash.phash(image: image4)
        print(phash4!)
        print(SwiftImageHash.distanceBetween(phash2!, phash4!)!)
        print(SwiftImageHash.distanceBetween(phash3!, phash4!)!)
        
        guard let image5 = loadImageFromResource(named: "Mandrill") else {
            XCTFail("Failed to load the image.")
            return
        }
        let phash5 = SwiftImageHash.phash(image: image5)
        print(phash5!)
        print(SwiftImageHash.distanceBetween(phash3!, phash5!)!)
        print(SwiftImageHash.distanceBetween(phash4!, phash5!)!)
        
        guard let image6 = loadImageFromResource(named: "Pepper") else {
            XCTFail("Failed to load the image.")
            return
        }
        let phash6 = SwiftImageHash.phash(image: image6)
        print(phash6!)
        print(SwiftImageHash.distanceBetween(phash4!, phash6!)!)
        print(SwiftImageHash.distanceBetween(phash5!, phash6!)!)
    }
}
