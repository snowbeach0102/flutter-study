# flutter-study

# 1주차 과제: Flutter·Dart 개발환경 구성

## 1. 개발 환경

- OS: Windows 11 Home 64-bit
- IDE: Visual Studio Code
- Flutter SDK: 3.47.2 (stable)
- Git & GitHub Desktop 연동 완료

## 2. flutter doctor 실행 결과

---

PS C:\jsp\apache-tomcat-11.0.25\webapps\ROOT> flutter doctor
[1/10] Material Fonts (2.2MB in 0.5s)
[2/10] Gradle Wrapper (0.1MB in 0.0s)
[3/10] Flutter SDK
├─ [1/5] sky_engine (1.5MB in 0.2s)
├─ [2/5] flutter_gpu (0.1MB in 0.0s)
├─ [3/5] flutter_patched_sdk (3.9MB in 0.7s)
├─ [4/5] flutter_patched_sdk_product (3.9MB in 0.7s)
└─ [5/5] windows-x64 (29.1MB in 4.9s)
[10/10] windows-x64/font-subset (2.1MB in 0.3s)
Doctor summary (to see all details, run flutter doctor -v):
[√] Flutter (Channel stable, 3.47.2, on Microsoft Windows [Version 10.0.26200.9168], locale ko-KR)
[√] Windows Version (11 Home 64-bit, 25H2, 2009)
[X] Android toolchain - develop for Android devices `latest 버전에서 16.0 버전 변경-> flutter doctor --android-licenses 입력후 전부 동의-> 해결.`
X Unable to locate Android SDK.
Install Android Studio from: https://developer.android.com/studio/index.html
On first launch it will assist you in installing the Android SDK components.
(or visit https://flutter.dev/to/windows-android-setup for detailed instructions).
If the Android SDK has been installed to a custom location, please use
`flutter config --android-sdk` to update to that location.

[√] Chrome - develop for the web
[X] Visual Studio - develop Windows apps `Visual Studio 항목: 모바일 앱(Android) 개발이 목적이므로 Windows 데스크톱 프로그램 빌드 도구는 설치하지 않고 유지함. `
X Visual Studio not installed; this is necessary to develop Windows apps.
Download at https://visualstudio.microsoft.com/downloads/.
Please install the "Desktop development with C++" workload, including all of its default components
[√] Connected device (3 available)
[√] Network resources

! Doctor found issues in 2 categories.

`해결 이후 `

flutter doctor
Doctor summary (to see all details, run flutter doctor -v):
[√] Flutter (Channel stable, 3.47.2, on Microsoft Windows [Version 10.0.26200.9168], locale ko-KR)
[√] Windows Version (11 Home 64-bit, 25H2, 2009)
[√] Android toolchain - develop for Android devices (Android SDK version 36.0.0)
[√] Chrome - develop for the web
[X] Visual Studio - develop Windows apps
X Visual Studio not installed; this is necessary to develop Windows apps.
Download at https://visualstudio.microsoft.com/downloads/.
Please install the "Desktop development with C++" workload, including all of its default components
[√] Connected device (3 available)
[√] Network resources

! Doctor found issues in 1 category.
