//
//  AppDelegate.swift
//  ios-swift
//
//  Created by Claude on 11/21/25.
//

import UIKit

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

        // UnityBridge 델리게이트 설정 (필요시)
        // UnityBridge.shared.delegate = self

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

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("[AppDelegate] Did Enter Background")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        print("[AppDelegate] Will Enter Foreground")
    }
}
