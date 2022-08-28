import Foundation
import SwiftUI

final class ContentViewModel: ObservableObject {
    @Published var isReady: Bool = false
    let pipManager: PiPManager = .shared

    func didTapMainButton() {
        if isReady {
            pipManager.reset()
        } else {
            pipManager.prepare()
        }
        isReady.toggle()
    }

    func didTapPiPSwap() {
        pipManager.swapPictureInPicture()
    }
}
