import AVKit
import AVFoundation
import UIKit

final class PiPManager: NSObject {
    public static let height: CGFloat = 120
    public static let shared: PiPManager = .init()
    public var bufferDisplayLayer: AVSampleBufferDisplayLayer = .init()

    private var pipController: AVPictureInPictureController?
    private var timer: Timer?
    private var pause: Bool = false

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.frame = .init(
            origin: .zero,
            size: .init(
                width: UIScreen.main.bounds.width,
                height: PiPManager.height
            )
        )
        label.font = .monospacedSystemFont(ofSize: 24, weight: .medium)
        label.textAlignment = .center
        label.textColor = .black
        label.backgroundColor = .white
        return label
    }()

    override init() {
        /**
         PiPするにはAudioSessionをactiveにしておく必要がある
         playAndRecordとmoviewPlaybackの組み合わせで音声を止めずにPiPをすることができる
         */
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .moviePlayback)
            try session.setActive(true)
        } catch {
            print("Failed to set AVAudioSession: \(error)")
        }
    }

    func prepare() {
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return }
        if let sampleBuffer = nextBuffer() {
            bufferDisplayLayer.enqueue(sampleBuffer)
        }

        let timerBlock: ((Timer) -> Void) = { [weak self] timer in
            guard let buffer: CMSampleBuffer = self?.nextBuffer() else { return }
            self?.bufferDisplayLayer.enqueue(buffer)
        }

        let timer = Timer(timeInterval: 1, repeats: true, block: timerBlock)
        self.timer = timer
        RunLoop.main.add(timer, forMode: .default)

        pipController = AVPictureInPictureController(
            contentSource: AVPictureInPictureController.ContentSource(
                sampleBufferDisplayLayer: bufferDisplayLayer,
                playbackDelegate: self
            )
        )
        pipController?.delegate = self
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        pipController = nil
    }

    private func nextBuffer() -> CMSampleBuffer? {
        /**
         AVSampleBufferDisplayLayerが壊れた時に復旧する
         （PiP中にYoutubeなど再生したら壊れることがあるため）
         */
        if bufferDisplayLayer.status == .failed {
            bufferDisplayLayer.flush()
        }
        dateLabel.text = Date().formatted(date: .numeric, time: .complete)

        return dateLabel.toCMSampleBuffer()
    }

    func swapPictureInPicture() {
        if pipController?.isPictureInPictureActive == true {
            pipController?.stopPictureInPicture()
        } else {
            pipController?.startPictureInPicture()
        }
    }
}

extension PiPManager: AVPictureInPictureControllerDelegate {
    // NOTE: Picture in Pictureの開始されることを通知
    func pictureInPictureControllerWillStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {}
    // NOTE: Picture in Pictureが開始されたこと通知
    func pictureInPictureControllerDidStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {}
    // NOTE: Picture in Pictureの起動に失敗したことを通知
    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {}
    // NOTE: Picture in Pictureが停止することを通知
    func pictureInPictureControllerWillStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {}
    // NOTE: Picture in Pictureが停止したことを通知
    func pictureInPictureControllerDidStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {}
}

extension PiPManager: AVPictureInPictureSampleBufferPlaybackDelegate {
    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        setPlaying playing: Bool
    ) {
        pause.toggle()
        dateLabel.text = "pause: \(pause)"
        if let sampleBuffer = dateLabel.toCMSampleBuffer() {
            bufferDisplayLayer.enqueue(sampleBuffer)
        }
    }

    func pictureInPictureControllerTimeRangeForPlayback(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> CMTimeRange {
        return CMTimeRange(
            start: .negativeInfinity,
            duration: .positiveInfinity
        )
    }

    func pictureInPictureControllerIsPlaybackPaused(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> Bool {
        return pause
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        didTransitionToRenderSize newRenderSize: CMVideoDimensions
    ) {
        dateLabel.text = "w: \(newRenderSize.width) h: \(newRenderSize.height)"
        if let sampleBuffer = dateLabel.toCMSampleBuffer() {
            bufferDisplayLayer.enqueue(sampleBuffer)
        }
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        skipByInterval skipInterval: CMTime,
        completion completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
