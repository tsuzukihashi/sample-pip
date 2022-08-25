import SwiftUI
import AVFoundation.AVSampleBufferDisplayLayer

struct PiPContainerView: UIViewRepresentable {
    let bufferDisplayLayer: AVSampleBufferDisplayLayer
    let frame: CGRect

    func makeUIView(context: Context)  -> UIView {
        let view = UIView()
        view.frame = frame
        bufferDisplayLayer.frame = view.bounds
        bufferDisplayLayer.videoGravity = .resizeAspect
        view.layer.addSublayer(bufferDisplayLayer)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
