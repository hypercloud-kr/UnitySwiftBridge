// AppDelegate.swift에 추가해야 할 내용
//
// 1. 파일 상단에 추가:
import UIKit

// 2. AppDelegate 클래스 추가 (없으면 생성):
class AppDelegate: NSObject, UIApplicationDelegate {

    static var shared: AppDelegate? {
        UIApplication.shared.delegate as? AppDelegate
    }

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        print("[AppDelegate] didFinishLaunchingWithOptions")

        // Unity 로드만 하고 시작은 하지 않음 (필요할 때 시작)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("[AppDelegate] Loading Unity framework...")
            UnityManager.shared.loadUnity()
            print("[AppDelegate] Unity loaded (not started yet)")
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        print("[AppDelegate] Will Resign Active - Pausing Unity")
        UnityManager.shared.pauseUnity()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("[AppDelegate] Did Become Active - Resuming Unity")
        UnityManager.shared.resumeUnity()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        print("[AppDelegate] Will Terminate - Unloading Unity")
        UnityManager.shared.unloadUnity()
    }
}

// 3. SwiftUI App 파일에 추가 (@main이 있는 파일):
// @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate