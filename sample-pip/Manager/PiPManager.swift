import AVKit
import AVFoundation
import UIKit

final class PiPManager: NSObject {
    public static let height: CGFloat = 120

    public static let shared: PiPManager = .init()

    override init() {
        // PiPするにはAudioSessionをactiveにしておく必要がある
        let session = AVAudioSession.sharedInstance()
        do {
            // playAndRecordとmoviewPlaybackの組み合わせで音声を止めずにPiPをすることができる
            try session.setCategory(.playAndRecord, mode: .moviePlayback)
            try session.setActive(true)
        } catch {
            print("Failed to set AVAudioSession: \(error)")
        }
    }

    public var bufferDisplayLayer: AVSampleBufferDisplayLayer = .init()

    private var timer: Timer?
    private var pipController: AVPictureInPictureController?

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

    func start() {
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return }
        if let sampleBuffer = dateLabel.toCMSampleBuffer() {
            bufferDisplayLayer.enqueue(sampleBuffer)
        }

        let timerBlock: ((Timer) -> Void) = { [weak self] timer in
            guard let buffer: CMSampleBuffer = self?.nextBuffer() else { return }
            self?.bufferDisplayLayer.enqueue(buffer)
        }

        let timer = Timer(timeInterval: 0.1, repeats: true, block: timerBlock)
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

    func stop() {
        timer?.invalidate()
        timer = nil
        pipController = nil
    }

    func nextBuffer() -> CMSampleBuffer? {
        // AVSampleBufferDisplayLayerが壊れた時に復旧する
        // （PiP中にYoutubeなど再生したら壊れることがあるため）
        if bufferDisplayLayer.status == .failed {
            bufferDisplayLayer.flush()
        }
        dateLabel.text = Date().formatted(date: .numeric, time: .complete)

        return dateLabel.toCMSampleBuffer()
    }

    func swapPictureInPicture() {
        if isPiP() {
            pipController?.stopPictureInPicture()
        } else {
            pipController?.startPictureInPicture()
        }
    }

    func isPiP() -> Bool {
        guard let pipController = pipController else { return false }
        return pipController.isPictureInPictureActive
    }
}

extension PiPManager: AVPictureInPictureControllerDelegate {
    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {}

    func pictureInPictureControllerWillStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {}

    func pictureInPictureControllerWillStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {}
}

extension PiPManager: AVPictureInPictureSampleBufferPlaybackDelegate {
    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        setPlaying playing: Bool
    ) {}

    func pictureInPictureControllerTimeRangeForPlayback(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> CMTimeRange {
        return CMTimeRange(start: .negativeInfinity, duration: .positiveInfinity)
    }

    func pictureInPictureControllerIsPlaybackPaused(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> Bool {
        return false
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        didTransitionToRenderSize newRenderSize: CMVideoDimensions
    ) {}

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        skipByInterval skipInterval: CMTime,
        completion completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
