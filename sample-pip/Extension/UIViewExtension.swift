import UIKit
import CoreMedia

extension UIView {
    // CMSampleBuffer: システムがメディアサンプルデータをメディアパイプラインで移動するために使用するオブジェクト
    func toCMSampleBuffer() -> CMSampleBuffer? {
        let scale: CGFloat = UIScreen.main.scale
        let size: CGSize = .init(width: bounds.width * scale, height: bounds.height * scale)
        guard let pixelBuffer = makeCVPixelBuffer(scale: scale, size: size) else { return nil }
        defer {
            // イメージバッファのアンロック
            CVPixelBufferUnlockBaseAddress(pixelBuffer,  CVPixelBufferLockFlags(rawValue: 0))
        }
        /**
         イメージバッファのロック
         ロックを保持したままバッファのデータを変更する予定がない場合
         このフラグを設定すると、Core Video がバッファの内容の既存のキャッシュを無効にするのを防ぐことができるため、パフォーマンスが向上
         */
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        guard let context = makeCGContext(scale: scale, size: size, pixelBuffer: pixelBuffer) else { return nil }
        layer.render(in: context)

        guard let formatDescription = makeCMFormatDescription(pixelBuffer: pixelBuffer) else { return nil }

        do {
            return try CMSampleBuffer(
                imageBuffer: pixelBuffer,
                formatDescription: formatDescription,
                sampleTiming: getCMSampleTimingInfo()
            )
        } catch {
            assertionFailure("Failed to create CMSampleBuffer: \(error)")
            return nil
        }
    }

    private func makeCVPixelBuffer(scale: CGFloat, size: CGSize) -> CVPixelBuffer? {
        /**
         CVPixelBufferを作る
         メインメモリ内のピクセルを保持するイメージバッファであり、フレームを生成するアプリや、Core Imageを使用するアプリで利用
         */
        var pixelBuffer: CVPixelBuffer?
        let createPixelBufferResult: OSStatus = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32ARGB,
            [
                kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue!,
                kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue!,
                kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary,
            ] as CFDictionary,
            &pixelBuffer
        )

        if createPixelBufferResult != kCVReturnSuccess {
            assertionFailure("Failed to create CVPixelBuffer: \(createPixelBufferResult)")
            return nil
        }

        return pixelBuffer
    }

    private func makeCGContext(scale: CGFloat, size: CGSize, pixelBuffer: CVPixelBuffer) -> CGContext? {
        // Quartz 2Dの描画先を作る
        guard let context: CGContext = .init(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else { return nil }

        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: scale, y: -scale)
        return context
    }

    private func makeCMFormatDescription(pixelBuffer: CVPixelBuffer) -> CMFormatDescription? {
        // メディアデータを記述
        var formatDescription: CMFormatDescription?
        let createImageBufferResult: OSStatus = CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription
        )

        if createImageBufferResult != kCVReturnSuccess {
            assertionFailure("Failed to create CMFormatDescription: \(createImageBufferResult)")
            return nil
        }

        return formatDescription
    }

    private func getCMSampleTimingInfo() -> CMSampleTimingInfo {
        let preferredTimescale: CMTimeScale = 60
        let currentTime: CMTime = .init(
            seconds: CACurrentMediaTime(),
            preferredTimescale: preferredTimescale
        )
        // サンプルバッファ内のサンプルのタイミング情報
        let timingInfo: CMSampleTimingInfo = .init(
            duration: .init(seconds: 1, preferredTimescale: preferredTimescale),
            presentationTimeStamp: currentTime,
            decodeTimeStamp: currentTime
        )

        return timingInfo
    }
}

