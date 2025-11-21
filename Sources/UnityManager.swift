//
//  UnityManager.swift
//  ios-swift
//
//  Manages Unity lifecycle and integration
//

import Foundation
import UIKit
import UnityFramework

class UnityManager: NSObject {

    // MARK: - Singleton
    static let shared = UnityManager()

    // MARK: - Properties
    private var ufw: UnityFramework?
    private var isUnityLoaded = false
    private var isUnityRunning = false

    private override init() {
        super.init()
    }

    // MARK: - Unity Lifecycle

    /// Load Unity Framework
    func loadUnity() {
        guard !isUnityLoaded else {
            print("[UnityManager] Unity already loaded")
            return
        }

        guard let unityFramework = getUnityFramework() else {
            print("[UnityManager] Error: Failed to get Unity Framework")
            return
        }

        self.ufw = unityFramework
        isUnityLoaded = true

        // Set the bridge
        UnityBridge.shared.setUnityFramework(unityFramework)

        // Register app lifecycle notifications
        registerAppLifecycleNotifications()

        print("[UnityManager] Unity loaded successfully")
    }

    /// Show Unity window
    func showUnity(inWindow window: UIWindow) {
        guard let ufw = ufw else {
            print("[UnityManager] Error: Unity not loaded")
            return
        }

        // Unity가 이미 실행 중이면 리턴
        if isUnityRunning {
            print("[UnityManager] Unity already running")
            return
        }

        print("[UnityManager] Starting Unity...")

        // Show Unity
        ufw.setDataBundleId("com.unity3d.framework")
        ufw.register(self)

        ufw.runEmbedded(
            withArgc: CommandLine.argc,
            argv: CommandLine.unsafeArgv,
            appLaunchOpts: nil
        )

        isUnityRunning = true
        print("[UnityManager] Unity shown and running")
    }

    /// Pause Unity
    func pauseUnity() {
        ufw?.pause(true)
    }

    /// Resume Unity
    func resumeUnity() {
        ufw?.pause(false)
    }

    /// Show Unity if ready (for SwiftUI)
    func showUnityIfReady() {
        guard let ufw = ufw else {
            print("[UnityManager] Error: Unity not loaded")
            return
        }

        // Unity가 이미 실행 중이면 그냥 표시
        if isUnityLoaded {
            print("[UnityManager] Unity already running")
            return
        }

        // 메인 윈도우 가져오기
        if let window = UIApplication.shared.windows.first {
            showUnity(inWindow: window)
        }
    }

    /// Hide Unity window
    func hideUnity() {
        print("[UnityManager] Hiding Unity window")

        // Unity window 찾아서 숨기기
        for window in UIApplication.shared.windows {
            let windowClassName = NSStringFromClass(type(of: window))
            let rootVCClassName = window.rootViewController.map { NSStringFromClass(type(of: $0)) } ?? ""

            if windowClassName.contains("Unity") || rootVCClassName.contains("Unity") {
                print("[UnityManager] Found Unity window, hiding it")
                window.isHidden = true
            }
        }

        // Unity 일시정지
        pauseUnity()
    }

    /// Show Unity window again
    func showUnityWindow() {
        print("[UnityManager] Showing Unity window")

        // Unity window 찾아서 표시
        for window in UIApplication.shared.windows {
            let windowClassName = NSStringFromClass(type(of: window))
            let rootVCClassName = window.rootViewController.map { NSStringFromClass(type(of: $0)) } ?? ""

            if windowClassName.contains("Unity") || rootVCClassName.contains("Unity") {
                print("[UnityManager] Found Unity window, showing it")
                window.isHidden = false
                window.makeKeyAndVisible()
            }
        }

        // Unity 재개
        resumeUnity()
    }

    /// Unload Unity
    func unloadUnity() {
        guard let ufw = ufw else { return }

        ufw.unloadApplication()
        isUnityLoaded = false
        self.ufw = nil

        print("[UnityManager] Unity unloaded")
    }

    // MARK: - Unity Framework Loading

    private func getUnityFramework() -> UnityFramework? {
        let bundlePath = "\(Bundle.main.bundlePath)/Frameworks/UnityFramework.framework"

        guard let bundle = Bundle(path: bundlePath) else {
            print("[UnityManager] Error: Unity framework bundle not found at \(bundlePath)")
            return nil
        }

        guard bundle.isLoaded || bundle.load() else {
            print("[UnityManager] Error: Failed to load Unity framework bundle")
            return nil
        }

        guard let framework = bundle.principalClass?.getInstance() as? UnityFramework else {
            print("[UnityManager] Error: Failed to get Unity framework instance")
            return nil
        }

        return framework
    }

    // MARK: - App Lifecycle

    private func registerAppLifecycleNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }

    @objc private func applicationWillResignActive() {
        pauseUnity()
    }

    @objc private func applicationDidBecomeActive() {
        resumeUnity()
    }

    @objc private func applicationWillTerminate() {
        unloadUnity()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UnityFrameworkListener

extension UnityManager: UnityFrameworkListener {

    func unityDidUnload(_ notification: Notification!) {
        print("[UnityManager] Unity did unload")
        isUnityLoaded = false
        ufw = nil
    }

    func unityDidQuit(_ notification: Notification!) {
        print("[UnityManager] Unity did quit")
        isUnityLoaded = false
        ufw = nil
    }
}
