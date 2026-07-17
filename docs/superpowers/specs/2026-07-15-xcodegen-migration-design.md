# XcodeGen 전환 설계

- **작성일**: 2026-07-15
- **대상**: ruby-news iOS 앱 프로젝트 빌드 구성

## 배경 / 동기

`.xcodeproj/project.pbxproj`는 Xcode가 수시로 재작성해 Git 충돌과 리뷰 노이즈를 유발한다.
프로젝트 정의를 텍스트(`project.yml`)로 관리하고 `.xcodeproj`는 빌드 직전 생성하도록
전환해, 버전 관리 대상을 YAML 한 파일로 줄인다. CLI/AI 에이전트 중심 워크플로우와도 맞는다.

현재 `.xcodeproj`는 이미 `PBXFileSystemSynchronizedRootGroup`(폴더 동기화) 방식이라
pbxproj에 개별 파일 목록이 없다. 따라서 XcodeGen `sources`에 폴더만 지정하면 되므로
변환이 기계적이고 위험이 낮다.

## 목표 / 비목표

**목표**
- `project.yml` 하나로 현재 `.xcodeproj`와 **동등한** 프로젝트를 생성한다.
- `.xcodeproj`를 Git 추적에서 제거하고 gitignore 한다.
- `xcodegen generate` 단계를 빌드 워크플로우 문서에 반영한다.
- CLAUDE.md가 주장하지만 실제로는 미연결 상태인 SwiftLint 빌드 플러그인을 실제로 연결한다.

**비목표**
- `release.sh` 등 archive/notarize/install 배포 스크립트 작성 (별도 작업).
- 소스 코드, 앱 기능, 서버 계약 변경.
- 메이저 버전 업그레이드. 같은 메이저 내 최신 마이너/패치로는 올리되(위 "현재 상태"
  비고 참고), 1.x→2x 등 메이저 점프는 이 변경의 범위 밖이다. `Package.resolved`를
  추적해 잠금 버전을 고정한다(위 산출물 2~3 참고).

## 현재 상태 (사실 확인)

- 타깃 3개: `ruby-news`(application), `ruby-newsTests`(unit-test), `ruby-newsUITests`(ui-testing)
- 원격 패키지 5개와 버전 요구사항(모두 `upToNextMajorVersion`):
  - HotwireNative — `hotwired/hotwire-native-ios` ≥ 1.2.2 → product `HotwireNative`
  - SDWebImageSwiftUI — `SDWebImage/SDWebImageSwiftUI` ≥ 3.0.0
  - KeychainAccess — `kishikawakatsumi/KeychainAccess` ≥ 4.0.0
  - SwiftLint — `realm/SwiftLint` ≥ 0.57.0 (플러그인 용도)
  - Mocker — `WeTransfer/Mocker` ≥ 3.0.0 (테스트 타깃 전용)
- 위 수치는 마이그레이션 당시 main의 요구사항(사실 확인용). 전환과 함께 같은 메이저 내
  최신으로 floor를 올려 HotwireNative 1.3.0 / SDWebImageSwiftUI 3.1.4 / KeychainAccess 4.2.2 /
  SwiftLint 0.65.0 / Mocker 3.0.2를 최소로 지정하고 `Package.resolved`로 잠근다.
- 앱 타깃 패키지 의존성: HotwireNative, SDWebImageSwiftUI, KeychainAccess
- 테스트 타깃 패키지 의존성: Mocker
- **SwiftLint는 `packageReferences`에 존재하지만 어떤 타깃에도 build tool plugin으로 연결되어 있지 않다** (현재 빌드 중 실제 린트 미실행).
- 모든 `XCBuildConfiguration`의 `baseConfigurationReference`가 `Config/Signing.xcconfig`.
  - `Config/Signing.xcconfig`는 gitignore 됨(로컬 전용), `Config/Signing.xcconfig.example`만 추적됨.
  - xcconfig 내용: `APPLE_DEVELOPMENT_TEAM = <팀 ID>` 변수 정의만 포함.
  - `DEVELOPMENT_TEAM = $(APPLE_DEVELOPMENT_TEAM)` 매핑은 pbxproj 빌드 설정(각
    `XCBuildConfiguration`)에 있었으며, 전환 후에는 `project.yml` 최상위
    `settings.base`로 옮겨간다(xcconfig 자체에는 없음).
- 공유 스킴 없음 (`xcshareddata/xcschemes` 부재).
- 주요 설정값: bundle id 접두 `kr.stadia`, `IPHONEOS_DEPLOYMENT_TARGET = 26.4`,
  `SWIFT_VERSION = 5.0`, `TARGETED_DEVICE_FAMILY = "1,2"`, `MARKETING_VERSION = 1.0`,
  `CURRENT_PROJECT_VERSION = 1`.
- `xcodegen` 미설치, `brew`(/opt/homebrew/bin/brew) 사용 가능.

## 설계

### 산출물

1. **`project.yml`** (repo 루트) — 아래 구조.
2. **`.gitignore`** — `ruby-news.xcodeproj/`의 내용물은 무지하되 SwiftPM 잠금 파일
   (`.../xcshareddata/swiftpm/Package.resolved`)은 부정 규칙으로 재포함해 추적 유지.
   의존성 버전이 머신마다 표류하는 것을 막기 위함이다.
3. **`.xcodeproj` Git 추적 해제** — `git rm -r --cached ruby-news.xcodeproj`
   (단, `Package.resolved`는 위 부정 규칙으로 다시 추적에 포함).
4. **`CLAUDE.md` / `AGENTS.md`** 커맨드 섹션 — `xcodegen generate` 선행 단계 및 설치·셋업 안내 추가.

### `project.yml` 구조

```yaml
name: ruby-news
options:
  bundleIdPrefix: kr.stadia
  deploymentTarget:
    iOS: "26.4"
configFiles:
  Debug: Config/Signing.xcconfig
  Release: Config/Signing.xcconfig
settings:
  base:
    DEVELOPMENT_TEAM: "$(APPLE_DEVELOPMENT_TEAM)"   # xcconfig의 APPLE_DEVELOPMENT_TEAM에서 치환
    # Xcode 26.x 신규 프로젝트 기본값이나 XcodeGen 2.46.0 preset이 누락 — 명시 재현
    LOCALIZATION_PREFERS_STRING_CATALOGS: YES
    ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS: YES
    ENABLE_USER_SCRIPT_SANDBOXING: YES
  configs:
    Release:
      VALIDATE_PRODUCT: YES
packages:
  HotwireNative:
    url: https://github.com/hotwired/hotwire-native-ios
    majorVersion: 1.3.0
  SDWebImageSwiftUI:
    url: https://github.com/SDWebImage/SDWebImageSwiftUI
    majorVersion: 3.1.4
  KeychainAccess:
    url: https://github.com/kishikawakatsumi/KeychainAccess
    majorVersion: 4.2.2
  SwiftLint:
    url: https://github.com/realm/SwiftLint
    majorVersion: 0.65.0
  Mocker:
    url: https://github.com/WeTransfer/Mocker
    majorVersion: 3.0.2
targets:
  ruby-news:
    type: application
    platform: iOS
    sources: [ruby-news]
    dependencies:
      - package: HotwireNative
      - package: SDWebImageSwiftUI
      - package: KeychainAccess
    buildToolPlugins:               # 빌드 툴 플러그인은 dependencies가 아닌 별도 블록
      - plugin: SwiftLintBuildToolPlugin
        package: SwiftLint
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: kr.stadia.ruby-news
        # INFOPLIST_KEY_*, MARKETING_VERSION, CURRENT_PROJECT_VERSION,
        # TARGETED_DEVICE_FAMILY, ENABLE_PREVIEWS, ASSETCATALOG_*,
        # LD_RUNPATH_SEARCH_PATHS, SWIFT_* (현재 앱 타깃 값 그대로)
  ruby-newsTests:
    type: bundle.unit-test
    platform: iOS
    sources: [ruby-newsTests]
    dependencies:
      - target: ruby-news
      - package: Mocker
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: kr.stadia.ruby-newsTests
        # TEST_HOST, BUNDLE_LOADER, IPHONEOS_DEPLOYMENT_TARGET 등
  ruby-newsUITests:
    type: bundle.ui-testing
    platform: iOS
    sources: [ruby-newsUITests]
    dependencies:
      - target: ruby-news
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: kr.stadia.ruby-newsUITests
        # TEST_TARGET_NAME
```

### 설계 결정

- **소스는 폴더 지정만.** 현재도 폴더 동기화이므로 `sources: [<folder>]`로 동일하게 재현된다.
- **SwiftLint 빌드 플러그인 연결.** 앱 타깃에서 SwiftLint 패키지를 build tool plugin으로
  연결한다(`SwiftLintBuildToolPlugin`). CLAUDE.md 설명과 실제를 일치시킨다.
- **CLANG_WARN 등 표준 경고 설정은 명시하지 않는다.** XcodeGen 기본 `settingPresets`가
  대부분의 Xcode 신규 프로젝트 기본값을 채운다. 단, Xcode 26.x가 신규 프로젝트에 기록하는
  `LOCALIZATION_PREFERS_STRING_CATALOGS`, `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS`,
  `ENABLE_USER_SCRIPT_SANDBOXING`는 XcodeGen 2.46.0 preset에 누락되어 있어 별도 기입한다
  (위 `settings.base` 참고). non-default 값만 `settings.base`에 기입한다.
- **스킴은 XcodeGen 자동 생성**에 맡긴다(현재 공유 스킴 없음).
- **`configFiles`로 Signing.xcconfig 참조** — 현재 `baseConfigurationReference`와 동일 동작.

### 주의점

- `Config/Signing.xcconfig`는 gitignore 상태다. 신규 클론에서는 `.example`을 복사하지 않으면
  `xcodegen generate`가 실패할 수 있다. 이 셋업 단계를 CLAUDE.md/AGENTS.md에 명시한다.
  (현재도 pbxproj가 동일 파일을 참조하므로 셋업 요구는 새로 생기는 게 아니다.)
- SwiftLint를 빌드 플러그인으로 연결하면 **처음으로 빌드 중 실제 린트가 실행**된다. 기존에
  잡히지 않던 위반이 경고/에러로 표면화될 수 있으므로 검증 단계에서 확인한다.

## 검증 (성공 기준)

1. `brew install xcodegen` 성공.
2. `xcodegen generate`가 에러 없이 `ruby-news.xcodeproj`를 생성.
3. `xcodebuild -project ruby-news.xcodeproj -scheme ruby-news -destination 'platform=iOS Simulator,name=iPhone 17' build` 성공.
4. 동일 스킴 `test`가 통과 (SwiftLint 플러그인 동작 포함).
5. 생성된 pbxproj의 bundle ID(3개), `IPHONEOS_DEPLOYMENT_TARGET`, `SWIFT_VERSION`,
   패키지 URL/버전이 원본과 일치.
6. `git status`에서 `ruby-news.xcodeproj`가 추적되지 않음(ignored).

## 롤백

`project.yml` 도입과 gitignore 변경은 커밋 되돌리기로 원복 가능하며, `.xcodeproj`는
`git rm --cached`로 추적만 해제하고 로컬 파일은 보존되므로 언제든 재추적할 수 있다.
