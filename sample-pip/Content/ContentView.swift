import SwiftUI

struct ContentView: View {
    @StateObject var viewModel: ContentViewModel = .init()

    var body: some View {
        VStack(spacing: 32) {
            Text("Sample PiP")
                .font(.largeTitle)

            Image(systemName: "pip")
                .resizable()
                .scaledToFit()
                .frame(width: 80)

            HStack {
                Button {
                    viewModel.didTapMainButton()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: viewModel.isReady ? "stop.fill" : "play.fill")
                            .font(.title)
                        Text(viewModel.isReady ? "STOP" : "START")
                    }
                    .frame(width: 120)
                }
                .buttonStyle(.bordered)

                Button {
                    viewModel.didTapPiPSwap()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "pip.swap")
                            .font(.title)
                        Text("PiP Swap")
                    }
                    .frame(width: 120)
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.isReady)
            }

            PiPContainerView(
                bufferDisplayLayer: viewModel.pipManager.bufferDisplayLayer,
                frame: .init(
                    x: 0,
                    y:  0,
                    width: UIScreen.main.bounds.width,
                    height: PiPManager.height
                )
            )
            .frame(height: PiPManager.height)
            .animation(.easeIn, value: viewModel.isReady)
            .opacity(viewModel.isReady ? 1 : 0)
        }
    }
}
