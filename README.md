# Color Hunting App

Flutter로 만든 컬러 헌팅 앱입니다.

## 1. 개발 환경 준비

### 필수
- Flutter SDK 설치
- Xcode (iOS 빌드 시, macOS)
- Android Studio + Android SDK (Android 빌드 시)

### 권장 확인
```bash
flutter doctor
```

## 2. 프로젝트 실행

```bash
flutter pub get
flutter run
```

## 3. 로컬라이제이션(gen-l10n)

이 프로젝트는 `flutter: generate: true` 설정을 사용합니다.  
번역 수정은 `lib/l10n/app_*.arb` 파일에서 하고, 생성 파일(`app_localizations_*.dart`)은 직접 수정하지 않습니다.

```bash
flutter gen-l10n
```

## 4. Android 빌드

### APK (테스트/배포 전 확인용)
```bash
flutter build apk --release
```

산출물:
- `build/app/outputs/flutter-apk/app-release.apk`

### AAB (Play Store 업로드용)
```bash
flutter build appbundle --release
```

산출물:
- `build/app/outputs/bundle/release/app-release.aab`

## 5. iOS 빌드

### iOS release 빌드
```bash
flutter build ios --release
```

참고:
- 실제 배포용 서명/아카이브는 Xcode에서 `ios/Runner.xcworkspace` 열어 진행
- TestFlight/App Store 배포 시 Bundle ID, Signing Team, Provisioning Profile 설정 필요

## 6. 자주 쓰는 명령어

```bash
flutter analyze
flutter test
flutter clean
flutter pub get
```
