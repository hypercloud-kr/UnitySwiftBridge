# UnitySwiftBridge

Unity Framework를 iOS 네이티브 앱에 통합하기 위한 Swift 브릿지 라이브러리

## 📋 개요

이 라이브러리는 Unity Framework와 iOS Swift 간의 양방향 통신을 제공합니다.
- ✅ Swift → Unity 메시지 전송
- ✅ Unity → Swift 콜백 수신
- ✅ Unity 생명주기 관리
- ✅ SwiftUI 지원

## 🚀 빠른 시작

### 필요 사항

- iOS 14.0+
- Xcode 13.0+
- Swift 5.5+
- UnityFramework.framework (별도 제공)

### 설치

#### 파일 직접 추가

프로젝트에 다음 파일들을 추가:

```swift
Sources/
├── UnityManager.swift
├── UnityBridge.swift
└── UnityViewRepresentable.swift
```

#### 또는 Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/yourname/UnitySwiftBridge", from: "1.0.0")
]
```

### 기본 사용법

```swift
import UnitySwiftBridge

// 1. Unity 로드 (AppDelegate에서)
UnityManager.shared.loadUnity()

// 2. Unity 시작
if let window = UIApplication.shared.windows.first {
    UnityManager.shared.showUnity(inWindow: window)
}

// 3. Unity에 메시지 전송
UnityBridge.shared.sendMessage(
    to: "iOSBridge",
    method: "ReceiveJSONData",
    message: "{\"command\":\"test\"}"
)

// 4. Unity로부터 메시지 받기
class MyHandler: UnityBridgeDelegate {
    func unityDidReceiveMessage(_ message: String) {
        print("Received: \(message)")
    }
    // ... 다른 델리게이트 메서드
}

UnityBridge.shared.delegate = MyHandler()
```

## 📚 상세 문서

- **[통합 가이드](./통합_가이드.md)** - 전체 통합 과정 상세 설명
- **[API 문서](#api-문서)** - 클래스 및 메서드 레퍼런스

## 🎯 주요 기능

### UnityManager

Unity의 생명주기를 관리합니다.

```swift
// Unity 로드
UnityManager.shared.loadUnity()

// Unity 시작
UnityManager.shared.showUnity(inWindow: window)

// Unity 숨기기
UnityManager.shared.hideUnity()

// Unity 일시정지/재개
UnityManager.shared.pauseUnity()
UnityManager.shared.resumeUnity()

// Unity 언로드
UnityManager.shared.unloadUnity()
```

### UnityBridge

Swift와 Unity 간 양방향 통신을 제공합니다.

```swift
// 메시지 전송
UnityBridge.shared.sendMessage(
    to: "GameObject",
    method: "MethodName",
    message: "data"
)

// JSON 데이터 전송
let data: [String: Any] = ["command": "test", "value": 123]
UnityBridge.shared.sendJSONData(data)

// 델리게이트 설정
UnityBridge.shared.delegate = self
```

### UnityViewRepresentable

SwiftUI에서 Unity를 표시합니다.

```swift
struct ContentView: View {
    var body: some View {
        UnityViewRepresentable()
            .edgesIgnoringSafeArea(.all)
    }
}
```

## 📡 통신 프로토콜

### Swift → Unity

Unity의 `iOSBridge` GameObject로 메시지를 전송합니다.

**사용 가능한 메서드:**
- `ReceiveJSONData(string jsonData)` - JSON 데이터 수신
- `StartARSession(string config)` - AR 세션 시작
- `StopARSession(string dummy)` - AR 세션 정지
- `ResetARSession(string dummy)` - AR 세션 리셋
- `TogglePlaneDetection(string enabled)` - 평면 감지 토글

### Unity → Swift

Unity에서 네이티브 브릿지를 통해 Swift 델리게이트 메서드를 호출합니다.

**UnityBridgeDelegate 메서드:**
- `unityDidReceiveMessage(_ message: String)` - 일반 메시지
- `unityARPlaneDetected(planeId:position:)` - AR 평면 감지
- `unityARSessionStateChanged(_ state: String)` - AR 세션 상태
- `unityReady()` - Unity 준비 완료
- `unityRequestCloseView()` - Unity 닫기 요청

## 🔧 요구사항

### Xcode 프로젝트 설정

1. **UnityFramework 추가** (Embed & Sign)
2. **Data 폴더 추가** (folder reference)
3. **Bridging Header 생성**
4. **Build Settings 구성**
   - Framework Search Paths
   - Other Linker Flags: `-Wl,-U,_UnityReplayKitDelegate`
   - Enable Bitcode: No

상세 내용은 [통합 가이드](./통합_가이드.md)를 참고하세요.

## 📱 SwiftUI 예제

```swift
import SwiftUI
import UnitySwiftBridge

@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UnityManager.shared.loadUnity()
        }
        return true
    }
}

struct ContentView: View {
    @State private var showUnity = false
    @StateObject private var bridgeHandler = BridgeHandler()

    var body: some View {
        VStack {
            Button("Unity 시작") {
                if let window = UIApplication.shared.windows.first {
                    UnityManager.shared.showUnity(inWindow: window)
                }
                showUnity = true
            }
        }
        .onAppear {
            UnityBridge.shared.delegate = bridgeHandler
        }
        .sheet(isPresented: $showUnity) {
            UnityViewRepresentable()
                .edgesIgnoringSafeArea(.all)
        }
    }
}

class BridgeHandler: ObservableObject, UnityBridgeDelegate {
    func unityDidReceiveMessage(_ message: String) {
        print("Message: \(message)")
    }

    func unityARPlaneDetected(planeId: String, position: (x: Float, y: Float, z: Float)) {
        print("Plane: \(planeId)")
    }

    func unityARSessionStateChanged(_ state: String) {
        print("State: \(state)")
    }

    func unityReady() {
        print("Unity Ready")
    }

    func unityRequestCloseView() {
        print("Close requested")
    }
}
```

## ⚠️ 주의사항

1. **Unity 시작 타이밍**: Unity는 앱 시작 후 0.5초 이후에 로드하는 것을 권장합니다.
2. **Window 관리**: Unity는 자체 UIWindow를 생성하므로 명시적으로 숨기기/표시하기를 관리해야 합니다.
3. **스레드 안전성**: Unity 델리게이트 콜백에서 UI 업데이트 시 `DispatchQueue.main.async` 사용 필수.
4. **실제 기기 테스트**: AR 기능은 시뮬레이터에서 작동하지 않습니다.

## 🐛 문제 해결

### Unity가 시작되지 않음
- UnityFramework가 Embed & Sign으로 설정되어 있는지 확인
- Framework Search Paths 확인

### 통신이 작동하지 않음
- Unity 씬에 "iOSBridge" GameObject가 있는지 확인
- Delegate가 설정되어 있는지 확인

자세한 내용은 [통합 가이드](./통합_가이드.md)의 문제 해결 섹션을 참고하세요.

## 📄 라이선스

MIT License - 자유롭게 사용하세요.

## 🤝 기여

이슈 및 PR은 언제든 환영합니다!
