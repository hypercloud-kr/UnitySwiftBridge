//
//  UnityManager.swift
//  ios-swift
//
//  Manages Unity lifecycle and integration
//

import Foundation
import UIKit

// Define UnityFrameworkListener protocol since we can't import UnityFramework
@objc public protocol UnityFrameworkListener: AnyObject {
    @objc optional func unityDidUnload(_ notification: Notification!)
    @objc optional func unityDidQuit(_ notification: Notification!)
}

public class UnityManager: NSObject {

    // MARK: - Singleton
    public static let shared = UnityManager()

    // MARK: - Properties
    private var ufw: NSObject?
    private var isUnityLoaded = false
    private var isUnityRunning = false

    private override init() {
        super.init()
    }

    // MARK: - Unity Lifecycle

    /// Load Unity Framework
    public func loadUnity() {
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
    public func showUnity(inWindow window: UIWindow) {
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

        // Show Unity using dynamic method calls
        let setDataBundleIdSelector = NSSelectorFromString("setDataBundleId:")
        if ufw.responds(to: setDataBundleIdSelector) {
            ufw.perform(setDataBundleIdSelector, with: "com.unity3d.framework")
        }

        let registerSelector = NSSelectorFromString("registerFrameworkListener:")
        if ufw.responds(to: registerSelector) {
            ufw.perform(registerSelector, with: self)
        }

        // Call runEmbeddedWithArgc using NSInvocation for multiple parameters
        let runEmbeddedSelector = NSSelectorFromString("runEmbeddedWithArgc:argv:appLaunchOpts:")
        if ufw.responds(to: runEmbeddedSelector) {
            let signature = ufw.method(for: runEmbeddedSelector)
            typealias RunEmbeddedFunction = @convention(c) (AnyObject, Selector, Int32, UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?, NSDictionary?) -> Void
            let function = unsafeBitCast(signature, to: RunEmbeddedFunction.self)
            function(ufw, runEmbeddedSelector, CommandLine.argc, CommandLine.unsafeArgv, nil)
        }

        isUnityRunning = true
        print("[UnityManager] Unity shown and running")
    }

    /// Pause Unity
    public func pauseUnity() {
        guard let ufw = ufw else { return }

        let selector = NSSelectorFromString("pause:")
        if ufw.responds(to: selector) {
            ufw.perform(selector, with: NSNumber(value: true))
        }
    }

    /// Resume Unity
    public func resumeUnity() {
        guard let ufw = ufw else { return }

        let selector = NSSelectorFromString("pause:")
        if ufw.responds(to: selector) {
            ufw.perform(selector, with: NSNumber(value: false))
        }
    }

    /// Show Unity if ready (for SwiftUI)
    public func showUnityIfReady() {
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
    public func hideUnity() {
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
    public func showUnityWindow() {
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
    public func unloadUnity() {
        guard let ufw = ufw else { return }

        let selector = NSSelectorFromString("unloadApplication")
        if ufw.responds(to: selector) {
            ufw.perform(selector)
        }

        isUnityLoaded = false
        self.ufw = nil

        print("[UnityManager] Unity unloaded")
    }

    // MARK: - Unity Framework Loading

    private func getUnityFramework() -> NSObject? {
        let bundlePath = "\(Bundle.main.bundlePath)/Frameworks/UnityFramework.framework"

        guard let bundle = Bundle(path: bundlePath) else {
            print("[UnityManager] Error: Unity framework bundle not found at \(bundlePath)")
            return nil
        }

        guard bundle.isLoaded || bundle.load() else {
            print("[UnityManager] Error: Failed to load Unity framework bundle")
            return nil
        }

        // Get UnityFramework class dynamically
        guard let principalClass = bundle.principalClass else {
            print("[UnityManager] Error: No principal class found in Unity framework")
            return nil
        }

        // Call getInstance() method dynamically
        let getInstanceSelector = NSSelectorFromString("getInstance")
        guard principalClass.responds(to: getInstanceSelector) else {
            print("[UnityManager] Error: Principal class doesn't respond to getInstance")
            return nil
        }

        let getInstance = principalClass.method(for: getInstanceSelector)
        typealias GetInstanceFunction = @convention(c) (AnyObject, Selector) -> NSObject?
        let function = unsafeBitCast(getInstance, to: GetInstanceFunction.self)
        guard let framework = function(principalClass as AnyObject, getInstanceSelector) else {
            print("[UnityManager] Error: getInstance returned nil")
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

    public func unityDidUnload(_ notification: Notification!) {
        print("[UnityManager] Unity did unload")
        isUnityLoaded = false
        ufw = nil
    }

    public func unityDidQuit(_ notification: Notification!) {
        print("[UnityManager] Unity did quit")
        isUnityLoaded = false
        ufw = nil
    }
}
