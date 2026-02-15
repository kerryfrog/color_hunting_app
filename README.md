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

## ios 
프로모션 텍스트 
당신의 하루는 어떤 색인가요? Color Hunting은 일상을 색으로 기록하는 새로운 방법입니다. 오늘의 기분을 나타내는 색상을 정하고, 주변의 색들을 사냥하며 12장의 사진으로 특별한 콜라주를 완성해 보세요. 평범했던 풍경 속에서 아름다운 색을 찾아내는, 새로운 당신을 발견하게 될 거예요.

설명
당신의 일상을 색으로 기록하세요

당신의 하루는 어떤 색인가요?
Color Hunting는 평범한 일상을 특별한 색의 기록으로 바꾸는 새로운 사진 기반 기록 앱입니다.

오늘의 색상을 하나 정해보세요. 그리고 당신의 시선이 머무는 곳 어디에서든 그 색을 찾아 '헌팅'을 시작하세요. 공원의 꽃잎, 카페의 의자, 빛바랜 벽돌, 친구의 옷까지. 무심코 지나쳤던 모든 것들이 당신의 컬렉션이 됩니다.

주요 기능:
🎯 오늘의 타겟 컬러 설정: 매일 새로운 색을 목표로 설정하고 헌팅을 시작하세요.
📸 12장의 사진으로 컬러 헌팅: 주변의 사물과 풍경에서 타겟 컬러를 찾아 사진으로 수집합니다.
🎨 나만의 컬러 컬렉션: 완성된 헌팅을 수집하고 콜라주로 다운로드 할 수 있습니다.

키워드
Color, 컬러, 색상, 사진, 일기, 저널, 디자인, 팔레트, 영감, 기록