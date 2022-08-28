import UIKit
import CoreMedia

extension UIView {
    /**
     UIViewをCMSampleBufferに変換する
     */
    func toCMSampleBuffer() -> CMSampleBuffer? {
        let scale: CGFloat = UIScreen.main.scale
        let size: CGSize = .init(width: bounds.width * scale, height: bounds.height * scale)
        guard let pixelBuffer = makeCVPixelBuffer(scale: scale, size: size) else { return nil }
        defer {
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

    /**
     CVPixelBufferを作る
     メインメモリ内のピクセルを保持するイメージバッファであり、フレームを生成するアプリや、Core Imageを使用するアプリで利用
     */
    private func makeCVPixelBuffer(scale: CGFloat, size: CGSize) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let createPixelBufferResult: OSStatus = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32ARGB,
            [
                kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue as Any,
                kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue as Any,
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

    /**
     CGContextの作成
     */
    private func makeCGContext(scale: CGFloat, size: CGSize, pixelBuffer: CVPixelBuffer) -> CGContext? {
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

    /**
     CMFormatDescriptionの作成
     */
    private func makeCMFormatDescription(pixelBuffer: CVPixelBuffer) -> CMFormatDescription? {
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

    /**
     サンプルバッファ内のサンプルのタイミング情報の取得
     */
    private func getCMSampleTimingInfo() -> CMSampleTimingInfo {
        let preferredTimescale: CMTimeScale = 60
        let currentTime: CMTime = .init(
            seconds: CACurrentMediaTime(),
            preferredTimescale: preferredTimescale
        )
        let timingInfo: CMSampleTimingInfo = .init(
            duration: .init(seconds: 1, preferredTimescale: preferredTimescale),
            presentationTimeStamp: currentTime,
            decodeTimeStamp: currentTime
        )

        return timingInfo
    }
}
