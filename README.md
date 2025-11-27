# Unity Swift Bridge

Unity Framework를 iOS 네이티브 앱에 통합하기 위한 강력한 Swift 브릿지 라이브러리

[![Swift](https://img.shields.io/badge/Swift-5.5+-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-14.0+-blue.svg)](https://www.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 🎯 주요 기능

- **양방향 통신**: Swift와 Unity 간 원활한 메시지 교환
- **SwiftUI 지원**: 최신 UI 프레임워크 완벽 지원
- **생명주기 관리**: Unity의 완전한 생명주기 제어
- **AR Foundation 지원**: AR 세션 관리 및 평면 감지 내장
- **타입 안전 JSON 통신**: 구조화된 데이터 교환
- **스레드 안전 작업**: 안전한 크로스 스레드 통신 처리

## 📋 요구사항

- iOS 14.0 이상
- Xcode 13.0 이상
- Swift 5.5 이상
- Unity 2021.3 이상 (프레임워크 생성용)

## 🚀 설치 방법

### 수동 설치

1. 프로젝트에 다음 파일들을 복사:

```
UnityBridge/
├── UnityManager.swift
├── UnityBridge.swift
└── UnityViewRepresentable.swift
```

2. UnityFramework.framework를 프로젝트에 추가 (Embed & Sign)
3. 프로젝트 설정 구성 (자세한 내용은 [통합 가이드](./통합_가이드.md) 참조)

## 💡 빠른 시작

### 1. AppDelegate에서 Unity 초기화

```swift
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 앱 시작 후 Unity 초기화
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UnityManager.shared.loadUnity()
        }
        return true
    }
}
```

### 2. SwiftUI에서 Unity 뷰 표시

```swift
import SwiftUI

struct ContentView: View {
    @State private var showUnity = false

    var body: some View {
        VStack(spacing: 20) {
            Button("Unity 실행") {
                showUnity = true
            }
            .buttonStyle(.borderedProminent)
        }
        .sheet(isPresented: $showUnity) {
            UnityViewRepresentable()
                .edgesIgnoringSafeArea(.all)
        }
    }
}
```

### 3. Unity로 메시지 전송

```swift
// Unity로 JSON 데이터 전송
let data: [String: Any] = [
    "command": "startGame",
    "level": 1,
    "playerName": "Swift User"
]

UnityBridge.shared.sendJSONData(data)

// 또는 직접 메시지 전송
UnityBridge.shared.sendMessage(
    to: "GameController",
    method: "LoadLevel",
    message: "1"
)
```

### 4. Unity로부터 메시지 수신

```swift
class GameBridgeHandler: ObservableObject, UnityBridgeDelegate {
    @Published var gameScore: Int = 0
    @Published var gameState: String = "idle"

    func unityDidReceiveMessage(_ message: String) {
        // Unity 메시지 파싱
        if let data = message.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

            if let score = json["score"] as? Int {
                DispatchQueue.main.async {
                    self.gameScore = score
                }
            }

            if let state = json["state"] as? String {
                DispatchQueue.main.async {
                    self.gameState = state
                }
            }
        }
    }

    func unityReady() {
        print("Unity가 통신 준비 완료")
    }

    func unityRequestCloseView() {
        // Unity 종료 요청 처리
    }
}
```

## 📚 API 레퍼런스

### UnityManager

Unity의 생명주기를 관리하는 싱글톤 클래스

```swift
// Unity Framework 로드
UnityManager.shared.loadUnity()

// 윈도우에 Unity 표시
UnityManager.shared.showUnity(inWindow: window)

// Unity 뷰 숨기기
UnityManager.shared.hideUnity()

// Unity 일시정지/재개
UnityManager.shared.pauseUnity()
UnityManager.shared.resumeUnity()

// Unity 언로드 (정리)
UnityManager.shared.unloadUnity()
```

### UnityBridge

Swift와 Unity 간 양방향 통신 처리

```swift
// 메시지 수신을 위한 델리게이트 설정
UnityBridge.shared.delegate = myDelegate

// GameObject로 메시지 전송
UnityBridge.shared.sendMessage(
    to: "GameObject",      // 대상 GameObject 이름
    method: "MethodName",  // 호출할 메서드
    message: "data"        // 문자열 파라미터
)

// JSON 데이터 전송
UnityBridge.shared.sendJSONData(["key": "value"])

// AR 관련 명령
UnityBridge.shared.startARSession(config: ["planeDetection": true])
UnityBridge.shared.stopARSession()
UnityBridge.shared.resetARSession()
UnityBridge.shared.togglePlaneDetection(enabled: true)
```

### UnityBridgeDelegate

Unity 메시지 수신을 위한 프로토콜

```swift
protocol UnityBridgeDelegate: AnyObject {
    func unityDidReceiveMessage(_ message: String)
    func unityARPlaneDetected(planeId: String, position: (x: Float, y: Float, z: Float))
    func unityARSessionStateChanged(_ state: String)
    func unityReady()
    func unityRequestCloseView()
}
```

## 🔄 통신 프로토콜

### Swift → Unity

Unity의 `iOSBridge` GameObject로 메시지 전송. 사용 가능한 메서드:

- `ReceiveJSONData(string jsonData)` - JSON 데이터 수신
- `StartARSession(string config)` - AR 세션 시작
- `StopARSession(string dummy)` - AR 세션 정지
- `ResetARSession(string dummy)` - AR 세션 리셋
- `TogglePlaneDetection(string enabled)` - 평면 감지 토글

### Unity → Swift

Unity에서 네이티브 iOS 메서드 호출:

```csharp
// Unity C#에서
[DllImport("__Internal")]
private static extern void SendMessageToiOS(string message);

// iOS로 메시지 전송
SendMessageToiOS("{\"event\":\"gameComplete\",\"score\":100}");
```

## ⚙️ 프로젝트 설정

### 필수 빌드 설정

1. **Framework Search Paths**: `$(PROJECT_DIR)`
2. **Other Linker Flags**: `-Wl,-U,_UnityReplayKitDelegate`
3. **Enable Bitcode**: `No`
4. **Always Embed Swift Standard Libraries**: `Yes`

### Info.plist 추가 사항

```xml
<key>io.unity3d.framework</key>
<string>unity</string>
<key>CADisableMinimumFrameDurationOnPhone</key>
<true/>
```

## 🎨 예제 프로젝트

`/IOS_Example` 디렉토리에서 완전한 작동 예제 확인:
- SwiftUI 통합
- AR 기능
- 양방향 통신
- 상태 관리

## 💼 실전 예제

### 전체 SwiftUI 앱 예제

```swift
import SwiftUI

@main
struct UnityIntegrationApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var unityViewModel = UnityViewModel()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(unityViewModel)
        }
    }
}

class UnityViewModel: ObservableObject, UnityBridgeDelegate {
    @Published var isUnityLoaded = false
    @Published var unityMessage = ""
    @Published var arPlanesDetected = 0

    init() {
        UnityBridge.shared.delegate = self
    }

    func unityReady() {
        DispatchQueue.main.async {
            self.isUnityLoaded = true
        }
    }

    func unityDidReceiveMessage(_ message: String) {
        DispatchQueue.main.async {
            self.unityMessage = message
        }
    }

    func unityARPlaneDetected(planeId: String, position: (x: Float, y: Float, z: Float)) {
        DispatchQueue.main.async {
            self.arPlanesDetected += 1
        }
    }

    func unityARSessionStateChanged(_ state: String) {
        print("AR 상태 변경: \(state)")
    }

    func unityRequestCloseView() {
        // 종료 처리
    }
}

struct MainView: View {
    @EnvironmentObject var viewModel: UnityViewModel
    @State private var showUnity = false

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Unity Swift Bridge")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                if viewModel.isUnityLoaded {
                    Label("Unity 준비 완료", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Label("Unity 로딩 중...", systemImage: "clock")
                        .foregroundColor(.orange)
                }

                Button(action: {
                    showUnity = true
                }) {
                    Label("Unity AR 시작", systemImage: "arkit")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.isUnityLoaded)

                if !viewModel.unityMessage.isEmpty {
                    VStack(alignment: .leading) {
                        Text("최근 메시지:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.unityMessage)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }

                if viewModel.arPlanesDetected > 0 {
                    Label("\(viewModel.arPlanesDetected)개 평면 감지됨",
                          systemImage: "square.3.layers.3d")
                        .foregroundColor(.blue)
                }

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showUnity) {
                UnityARView()
            }
        }
    }
}

struct UnityARView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            UnityViewRepresentable()
                .edgesIgnoringSafeArea(.all)

            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        UnityManager.shared.hideUnity()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .onAppear {
            UnityBridge.shared.startARSession(config: [
                "planeDetection": true,
                "imageTracking": false
            ])
        }
        .onDisappear {
            UnityBridge.shared.stopARSession()
        }
    }
}
```

## ✅ 모범 사례

1. **초기화 타이밍**: 앱 시작 후 Unity 로드 (0.5초 지연 권장)
2. **스레드 안전성**: Unity 콜백 수신 시 UI 업데이트는 항상 메인 스레드에서
3. **메모리 관리**: 사용하지 않을 때는 Unity를 적절히 언로드
4. **에러 처리**: Unity 초기화 실패에 대한 적절한 에러 처리 구현
5. **테스팅**: AR 기능은 실제 기기에서 테스트

## 🔍 문제 해결

### Unity가 시작되지 않는 경우
- UnityFramework가 올바르게 임베드되었는지 확인 (Embed & Sign)
- Build Settings의 Framework Search Paths 확인
- Data 폴더가 폴더 참조로 추가되었는지 확인

### 통신이 작동하지 않는 경우
- Unity 씬에 "iOSBridge" GameObject가 존재하는지 확인
- 메시지 전송 전 델리게이트가 올바르게 설정되었는지 확인
- JSON 형식이 올바른지 확인

### AR 기능이 작동하지 않는 경우
- 실제 기기에서 테스트 (시뮬레이터는 AR 미지원)
- Info.plist에 카메라 권한 확인
- AR 세션 구성 확인

## 🤝 기여하기

기여를 환영합니다! Pull Request를 자유롭게 제출해주세요.

1. 저장소 Fork
2. 기능 브랜치 생성 (`git checkout -b feature/AmazingFeature`)
3. 변경사항 커밋 (`git commit -m 'Add some AmazingFeature'`)
4. 브랜치 푸시 (`git push origin feature/AmazingFeature`)
5. Pull Request 생성

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다 - 자세한 내용은 [LICENSE](LICENSE) 파일 참조

## 💬 지원

이슈, 질문 또는 제안사항은 GitHub 이슈를 열어주세요.

## 🙏 감사의 말

- Unity Technologies - Unity Framework
- Apple - SwiftUI와 ARKit
- iOS 개발 커뮤니티

---

Made with ❤️ by Hypercloud
