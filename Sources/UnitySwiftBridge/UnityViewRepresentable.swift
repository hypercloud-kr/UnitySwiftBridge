//
//  UnityViewRepresentable.swift
//  ios-swift
//
//  SwiftUI wrapper for Unity view
//

import SwiftUI
import UIKit

public struct UnityViewRepresentable: UIViewControllerRepresentable {

    public init() {}

    public func makeUIViewController(context: Context) -> UnityViewController {
        let controller = UnityViewController()

        // Unity가 로드되면 표시
        DispatchQueue.main.async {
            UnityManager.shared.showUnityIfReady()
        }

        return controller
    }

    public func updateUIViewController(_ uiViewController: UnityViewController, context: Context) {
        // 업데이트 필요 없음
    }
}

public class UnityViewController: UIViewController {

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        print("[UnityViewController] viewDidLoad")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("[UnityViewController] viewWillAppear")

        // Unity 재개
        UnityManager.shared.resumeUnity()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("[UnityViewController] viewWillDisappear")

        // Unity 일시정지
        UnityManager.shared.pauseUnity()
    }
}
