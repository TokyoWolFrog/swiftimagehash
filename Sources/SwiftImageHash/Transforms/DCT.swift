import Accelerate

func apply2DDCT(to buffer: vImage_Buffer, dctlength: Int = 32) -> [Float]? {
    let width = Int(buffer.width)
    let height = Int(buffer.height)
    if width != dctlength || height != dctlength { return nil }
    
    let imgbufferPointer = buffer.data.assumingMemoryBound(to: UInt8.self)
    var floatDataBuffer = [Float](repeating: 0, count: width * height)
    vDSP.convertElements(of: UnsafeBufferPointer(start: imgbufferPointer, count: width * height), to: &floatDataBuffer)
    
    guard let dct1D = vDSP.DCT(count: dctlength, transformType: .II) else {
        return nil
    }
    var tempDCTBuffer = [Float](repeating: 0, count: width * height)

    for row in 0..<height {
        let start = row * width
        dct1D.transform(floatDataBuffer[start..<start + width], result: &tempDCTBuffer[start..<start + width])
    }
    
    var transposedBuffer = [Float](repeating: 0, count: width * height)
    vDSP_mtrans(tempDCTBuffer, 1, &transposedBuffer, 1, vDSP_Length(width), vDSP_Length(height))
    
    for row in 0..<width {
        let start = row * height
        dct1D.transform(transposedBuffer[start..<start + height], result: &tempDCTBuffer[start..<start + height])
    }
    
    var topLeft8x8 = [Float](repeating: 0, count: 8 * 8)
    for row in 0..<8 {
        for col in 0..<8 {
            let indexInTempBuffer = row * width + col
            let indexInTopLeft = row * 8 + col
            topLeft8x8[indexInTopLeft] = tempDCTBuffer[indexInTempBuffer]
        }
    }
    return topLeft8x8
}

func apply2DDCTDispatchQueue(to buffer: vImage_Buffer, dctlength: Int = 32) -> [Float]? {
    let width = Int(buffer.width)
    let height = Int(buffer.height)
    if width != dctlength || height != dctlength { return nil }
    
    var floatDataBuffer = vImageBufferToArray(buffer: buffer)
    
    guard let dct1D = vDSP.DCT(count: dctlength, transformType: .II) else {
        return nil
    }

    DispatchQueue.concurrentPerform(iterations: height) { rowIndex in
        var row = floatDataBuffer[rowIndex]
        dct1D.transform(row, result: &row)
        floatDataBuffer[rowIndex] = row
    }
    
    var transposedBuffer = transpose(matrix: floatDataBuffer)
    DispatchQueue.concurrentPerform(iterations: width) { rowIndex in
        var row = transposedBuffer[rowIndex]
        dct1D.transform(row, result: &row)
        transposedBuffer[rowIndex] = row
    }
    
    var topLeft8x8 = [Float](repeating: 0, count: 8 * 8)
    DispatchQueue.concurrentPerform(iterations: 8) { rowIndex in
        for col in 0..<8 {
            let indexInTopLeft = rowIndex * 8 + col
            topLeft8x8[indexInTopLeft] = transposedBuffer[rowIndex][col]
        }
    }
    return topLeft8x8
}

func apply2DDCT(to buffer: vImage.PixelBuffer<vImage.Planar8>, dctlength: Int = 32) -> [Float]? {
    let width = Int(buffer.width)
    let height = Int(buffer.height)
    if width != dctlength || height != dctlength { return nil }
    
    guard let dct1D = vDSP.DCT(count: dctlength, transformType: .II) else {
        return nil
    }
    
    // Test
    /*
    guard let image = createUIImageFromBuffer(buffer) else { return nil }
    let result = saveImageSimulator(image: image, named: "resizeAndGrayscale.png")
    switch result {
    case .success(let path):
        print("Image saved successfully at path: \(path)")
    case .failure(let error):
        print("Failed to save image: \(error)")
    }
    */

    var tempBuffer = [Float](repeating: 0, count: width * height)
 
    var dctRowResults = [Float](repeating: 0, count: width)
    for row in 0..<height {
        let rowStartIndex = row * width
        var rowData = [Float](repeating: 0, count: width)
        for i in 0..<width {
            rowData[i] = Float(buffer.array[rowStartIndex+i])
        }
        dct1D.transform(rowData, result: &dctRowResults)
        tempBuffer.replaceSubrange(rowStartIndex..<rowStartIndex + width, with: dctRowResults)
    }
    
    var transposedBuffer = [Float](repeating: 0, count: width * height)
    vDSP_mtrans(tempBuffer, 1, &transposedBuffer, 1, vDSP_Length(width), vDSP_Length(height))
    // Test
    //printTopLeft8x8(from: transposedBuffer, width: width)
    
    for row in 0..<width { // Note: width becomes the 'height' after transpose
        let rowStartIndex = row * height
        var rowData = [Float](repeating: 0, count: width)
        for i in 0..<width {
            rowData[i] = transposedBuffer[row * height + i]
        }
        dct1D.transform(rowData, result: &dctRowResults)
        tempBuffer.replaceSubrange(rowStartIndex..<rowStartIndex + height, with: dctRowResults)
    }
    
    var topLeft8x8 = [Float](repeating: 0, count: 8 * 8)
    for row in 0..<8 {
        for col in 0..<8 {
            // Calculate the index in the tempBuffer for the current row and column
            let indexInTempBuffer = row * width + col
            // Calculate the index in the topLeft8x8 array
            let indexInTopLeft = row * 8 + col
            // Assign the value from tempBuffer to the topLeft8x8 array
            topLeft8x8[indexInTopLeft] = tempBuffer[indexInTempBuffer]
        }
    }
    return topLeft8x8
}

func apply2DDCTExecute(to buffer: inout vImage_Buffer, dctlength: Int) -> [Float]? {
    let width = Int(buffer.width)
    let height = Int(buffer.height)
    
    if width != dctlength || height != dctlength { return nil }
    
    // Create DCT Setup
    guard let dctSetup = vDSP_DCT_CreateSetup(nil, vDSP_Length(dctlength), vDSP_DCT_Type.II) else {
        print("Failed to create DCT setup.")
        return nil
    }
    defer { vDSP_DFT_DestroySetup(dctSetup) }
    
    let floatData = UnsafeMutablePointer<Float>.allocate(capacity: width * height)
    defer { floatData.deallocate() }
    var imgFloatBuffer = vImage_Buffer(data: floatData, height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: width * MemoryLayout<Float>.size)
    
    let error = vImageConvert_Planar8toPlanarF(&buffer, &imgFloatBuffer, 255, 0, vImage_Flags(kvImageNoFlags))
    if error != kvImageNoError {
        print("Error converting image: \(error)")
        return nil
    }
    
    // Test
    //printTopLeft8x8(from: buffer, as: UInt8.self)
    //printTopLeft8x8(from: imgFloatBuffer, as: Float.self)
    
    var tempBuffer = [Float](repeating: 0, count: width * height)
    
    let bufferPointer = imgFloatBuffer.data.assumingMemoryBound(to: Float.self)
    
    // Horizontal DCT (row-wise)
    for row in 0..<height {
        let rowPointer = bufferPointer.advanced(by: row * imgFloatBuffer.rowBytes / MemoryLayout<Float>.stride)
        var rowData = [Float](repeating: 0, count: width)
        for i in 0..<width {
            rowData[i] = rowPointer[i]
        }
        vDSP_DCT_Execute(dctSetup, &rowData, &tempBuffer[row * width])
    }
    
    // Transpose the result to prepare for vertical DCT
    var transposedBuffer = [Float](repeating: 0, count: width * height)
    vDSP_mtrans(tempBuffer, 1, &transposedBuffer, 1, vDSP_Length(width), vDSP_Length(height))
    // Test
    //printTopLeft8x8(from: transposedBuffer, width: width)
    
    // Vertical DCT (column-wise, now rows due to transpose)
    for row in 0..<width { // Note: width becomes the 'height' after transpose
        var rowData = [Float](repeating: 0, count: width)
        for i in 0..<width {
            rowData[i] = transposedBuffer[row * height + i]
        }
        vDSP_DCT_Execute(dctSetup, &rowData, &tempBuffer[row * height])
    }
    
    var topLeft8x8 = [Float](repeating: 0, count: 8 * 8)
    for row in 0..<8 {
        for col in 0..<8 {
            // Calculate the index in the tempBuffer for the current row and column
            let indexInTempBuffer = row * width + col
            // Calculate the index in the topLeft8x8 array
            let indexInTopLeft = row * 8 + col
            // Assign the value from tempBuffer to the topLeft8x8 array
            topLeft8x8[indexInTopLeft] = tempBuffer[indexInTempBuffer]
        }
    }
    return topLeft8x8
}

func transpose(matrix: [[Float]]) -> [[Float]] {
    guard !matrix.isEmpty else { return [[]] }
    
    let rowCount = matrix.count
    let colCount = matrix[0].count
    
    // Initialize a new matrix with dimensions swapped
    var transposedMatrix = [[Float]](repeating: [Float](repeating: 0, count: rowCount), count: colCount)
    
    for row in 0..<rowCount {
        for col in 0..<colCount {
            transposedMatrix[col][row] = matrix[row][col]
        }
    }
    
    return transposedMatrix
}

func vImageBufferToArray(buffer: vImage_Buffer) -> [[Float]] {
    let width = Int(buffer.width)
    let height = Int(buffer.height)
    let rowBytes = Int(buffer.rowBytes)

    var nestedArray = [[Float]](repeating: [Float](repeating: 0, count: width), count: height)
    
    for row in 0..<height {
        let rowData = buffer.data.advanced(by: row * rowBytes).assumingMemoryBound(to: UInt8.self)
        for col in 0..<width {
            nestedArray[row][col] = Float(rowData[col])
        }
    }
    
    return nestedArray
}

func printTopLeft8x8(from buffer: [Float], width: Int){
    let blockSize = 8
    for row in 0..<blockSize {
        for col in 0..<blockSize {
            let index = row * width + col
            print(String(format: "%.2f", buffer[index]), terminator: " ")
        }
        print()  // Newline after each row
    }
}

func printTopLeft8x8<T: Numeric & CustomStringConvertible>(from buffer: vImage_Buffer, as type: T.Type) {
    let width = Int(buffer.width)
    let height = Int(buffer.height)
    let rowBytes = Int(buffer.rowBytes)
    
    // Ensure the buffer is large enough
    guard width >= 8, height >= 8 else {
        print("Buffer is too small to contain an 8x8 block.")
        return
    }
    
    // Access the buffer's data
    let data = buffer.data.bindMemory(to: type, capacity: rowBytes * height / MemoryLayout<T>.stride)
    
    // Iterate over the first 8 rows and columns to access the top-left 8x8 block
    for row in 0..<8 {
        var rowValues: [T] = []
        for col in 0..<8 {
            let index = (row * rowBytes + col * MemoryLayout<T>.stride) / MemoryLayout<T>.stride  // Calculate the index for the current element
            rowValues.append(data[index])  // Append the value to the row's results
        }
        // Print the current row of the 8x8 block
        print(rowValues)
    }
}
