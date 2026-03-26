import SwiftUI
import UIKit

struct NavigationBarVisibilityHost: UIViewControllerRepresentable {
    let isHidden: Bool

    func makeUIViewController(context: Context) -> Controller {
        Controller(isHidden: isHidden)
    }

    func updateUIViewController(_ controller: Controller, context: Context) {
        controller.isHidden = isHidden
        controller.applyVisibility()
    }

    final class Controller: UIViewController {
        var isHidden: Bool

        init(isHidden: Bool) {
            self.isHidden = isHidden
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            applyVisibility()
        }

        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            navigationController?.setNavigationBarHidden(false, animated: false)
        }

        func applyVisibility() {
            navigationController?.setNavigationBarHidden(isHidden, animated: false)
        }
    }
}

extension View {
    func hostNavigationBarHidden(_ hidden: Bool) -> some View {
        background(NavigationBarVisibilityHost(isHidden: hidden))
    }
}
