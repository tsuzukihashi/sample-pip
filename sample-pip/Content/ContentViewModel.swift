import Foundation
import SwiftUI

final class ContentViewModel: ObservableObject {
    @Published var running: Bool = false
    let pipManager: PiPManager

    init() {
        pipManager = .shared
    }

    func didTapMainButton() {
        if running {
            pipManager.stop()
        } else {
            pipManager.start()
        }
        running.toggle()
    }

    func didTapPiPSwap() {
        pipManager.swapPictureInPicture()
    }
}
