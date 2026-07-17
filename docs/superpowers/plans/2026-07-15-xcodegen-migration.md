# XcodeGen 전환 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ruby-news iOS 프로젝트를 `project.yml` 기반 XcodeGen으로 전환해, 현재 `.xcodeproj`와 동등한 프로젝트를 텍스트로 관리한다.

**Architecture:** `project.yml` 하나가 프로젝트 정의의 단일 소스가 되고, `.xcodeproj`는 `xcodegen generate`로 매번 생성한다. 소스는 폴더 동기화(`sources: [<folder>]`), 패키지 5개와 빌드 설정은 현재 pbxproj 값을 그대로 재현하되, 지금까지 미연결이던 SwiftLint 빌드 플러그인을 실제로 연결한다. `.xcodeproj`는 Git 추적에서 제거하고 gitignore 한다.

**Tech Stack:** XcodeGen (Homebrew), Swift Package Manager, xcodebuild, iOS Simulator.

## Global Constraints

- 프로젝트명: `ruby-news`
- Bundle ID: 앱 `kr.stadia.ruby-news`, 유닛테스트 `kr.stadia.ruby-newsTests`, UI테스트 `kr.stadia.ruby-newsUITests`
- `IPHONEOS_DEPLOYMENT_TARGET = 26.4`, `SWIFT_VERSION = 5.0`, `TARGETED_DEVICE_FAMILY = "1,2"`
- `MARKETING_VERSION = 1.0`, `CURRENT_PROJECT_VERSION = 1`
- 패키지 요구사항(모두 `upToNextMajorVersion` = XcodeGen `majorVersion`).
  전환과 함께 같은 메이저 내 최신으로 floor를 올림(아래는 업그레이드 후 최소 버전):
  - HotwireNative `https://github.com/hotwired/hotwire-native-ios` ≥ 1.3.0 (product `HotwireNative`)
  - SDWebImageSwiftUI `https://github.com/SDWebImage/SDWebImageSwiftUI` ≥ 3.1.4
  - KeychainAccess `https://github.com/kishikawakatsumi/KeychainAccess` ≥ 4.2.2
  - SwiftLint `https://github.com/realm/SwiftLint` ≥ 0.65.0 (build tool plugin)
  - Mocker `https://github.com/WeTransfer/Mocker` ≥ 3.0.2 (테스트 타깃 전용)
- 앱 타깃 패키지 의존성: HotwireNative, SDWebImageSwiftUI, KeychainAccess + SwiftLint 플러그인
- 테스트 타깃 패키지 의존성: Mocker
- Base config: 모든 config가 `Config/Signing.xcconfig` 참조 (gitignore됨, 로컬 전용)
- 빌드/테스트 명령: `xcodebuild -project ruby-news.xcodeproj -scheme ruby-news -destination 'platform=iOS Simulator,name=iPhone 17' <build|test>`
- 패키지 우선 원칙(AGENTS.md §7), 표준 CLANG_WARN 등은 XcodeGen 기본 preset에 위임하고 non-default만 명시

---

### Task 1: XcodeGen 설치 및 원본 설정 스냅샷 확보

**Files:**
- 없음 (환경 준비 + 참조 스냅샷)

**Interfaces:**
- Consumes: 없음
- Produces: `xcodegen` CLI 사용 가능. `/private/tmp/claude-501/.../scratchpad/pbxproj-original.txt`에 원본 pbxproj 사본(대조용).

- [ ] **Step 1: xcodegen 설치**

Run:
```bash
brew install xcodegen
```
Expected: 설치 성공. 이미 설치돼 있으면 "already installed"도 무방.

- [ ] **Step 2: 설치 확인**

Run:
```bash
xcodegen --version
```
Expected: 버전 문자열 출력 (예: `Version: 2.x.x`).

- [ ] **Step 3: 원본 pbxproj 대조용 사본 보관**

Run:
```bash
cp ruby-news.xcodeproj/project.pbxproj "$SCRATCH/pbxproj-original.txt"
```
(`$SCRATCH` = 세션 scratchpad 디렉터리. Task 4에서 생성 결과와 대조하는 데 사용.)
Expected: 파일 복사 성공. 이 Task는 커밋 없음(환경 준비 단계).

---

### Task 2: project.yml 작성

**Files:**
- Create: `project.yml`

**Interfaces:**
- Consumes: Task 1의 `xcodegen` CLI.
- Produces: repo 루트 `project.yml`. Task 3이 `xcodegen generate`로 소비.

- [ ] **Step 1: project.yml 작성**

`project.yml` (repo 루트) 전체 내용:

```yaml
name: ruby-news
options:
  bundleIdPrefix: kr.stadia
  deploymentTarget:
    iOS: "26.4"
  developmentLanguage: en

configFiles:
  Debug: Config/Signing.xcconfig
  Release: Config/Signing.xcconfig

settings:
  base:
    DEVELOPMENT_TEAM: "$(APPLE_DEVELOPMENT_TEAM)"
    # Defaults newer Xcode (26.x) writes into new projects but XcodeGen 2.46.0
    # presets don't emit — reproduce them explicitly to match the pre-migration project.
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
    sources:
      - ruby-news
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: kr.stadia.ruby-news
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: 1
        TARGETED_DEVICE_FAMILY: "1,2"
        CODE_SIGN_STYLE: Automatic
        ENABLE_PREVIEWS: YES
        GENERATE_INFOPLIST_FILE: YES
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
        STRING_CATALOG_GENERATE_SYMBOLS: YES
        SWIFT_VERSION: "5.0"
        SWIFT_APPROACHABLE_CONCURRENCY: YES
        SWIFT_DEFAULT_ACTOR_ISOLATION: MainActor
        SWIFT_EMIT_LOC_STRINGS: YES
        SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY: YES
        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: YES
        INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents: YES
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone: "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
        LD_RUNPATH_SEARCH_PATHS:
          - $(inherited)
          - "@executable_path/Frameworks"
    dependencies:
      - package: HotwireNative
      - package: SDWebImageSwiftUI
      - package: KeychainAccess
    buildToolPlugins:
      - plugin: SwiftLintBuildToolPlugin
        package: SwiftLint

  ruby-newsTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - ruby-newsTests
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: kr.stadia.ruby-newsTests
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: 1
        TARGETED_DEVICE_FAMILY: "1,2"
        CODE_SIGN_STYLE: Automatic
        GENERATE_INFOPLIST_FILE: YES
        IPHONEOS_DEPLOYMENT_TARGET: "26.4"
        SWIFT_VERSION: "5.0"
        SWIFT_APPROACHABLE_CONCURRENCY: YES
        SWIFT_EMIT_LOC_STRINGS: NO
        SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY: YES
        STRING_CATALOG_GENERATE_SYMBOLS: NO
    dependencies:
      - target: ruby-news
      - package: Mocker

  ruby-newsUITests:
    type: bundle.ui-testing
    platform: iOS
    sources:
      - ruby-newsUITests
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: kr.stadia.ruby-newsUITests
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: 1
        TARGETED_DEVICE_FAMILY: "1,2"
        CODE_SIGN_STYLE: Automatic
        GENERATE_INFOPLIST_FILE: YES
        SWIFT_VERSION: "5.0"
        SWIFT_APPROACHABLE_CONCURRENCY: YES
        SWIFT_EMIT_LOC_STRINGS: NO
        SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY: YES
        STRING_CATALOG_GENERATE_SYMBOLS: NO
    dependencies:
      - target: ruby-news
```

참고:
- 유닛테스트의 `TEST_HOST`/`BUNDLE_LOADER`, UI테스트의 `TEST_TARGET_NAME`은 XcodeGen이
  `dependencies: - target: ruby-news`(테스트 타깃)에서 자동 설정하므로 명시하지 않는다.
- SwiftLint 플러그인 이름은 `SwiftLintBuildToolPlugin`. 빌드 툴 플러그인은
  `dependencies:`가 아니라 별도의 `buildToolPlugins:` 블록에 지정한다(초기 설계에서는
  `dependencies:` 아래 `plugin:` 키로 시도했으나, XcodeGen은 이를 인식하지 못해
  `buildToolPlugins:`로 이동 — Task 3 generate 결과로 확정).

- [ ] **Step 2: YAML 유효성 확인 (generate 없이 파싱)**

Run:
```bash
xcodegen dump --spec project.yml --type json >/dev/null && echo "SPEC OK"
```
Expected: `SPEC OK`. 파싱/스키마 오류가 있으면 여기서 메시지가 나옴 → 수정 후 재실행.

- [ ] **Step 3: 커밋**

```bash
git add project.yml
git commit -m "feat: add XcodeGen project.yml"
```

---

### Task 3: 프로젝트 생성 및 원본 대비 검증

**Files:**
- 생성물: `ruby-news.xcodeproj` (아직 Git 추적 상태 — Task 5에서 해제)

**Interfaces:**
- Consumes: Task 2의 `project.yml`, Task 1의 스냅샷 `$SCRATCH/pbxproj-original.txt`.
- Produces: `xcodegen generate`로 재생성된 `ruby-news.xcodeproj`.

- [ ] **Step 1: 프로젝트 생성**

Run:
```bash
xcodegen generate --spec project.yml
```
Expected: `Created project at .../ruby-news.xcodeproj`. 경고 없이 완료.
SwiftLint `plugin:` 관련 오류가 나면 Task 2 Step 1의 플러그인 지정을 교정하고 재실행.

- [ ] **Step 2: 핵심 설정값이 생성물에 존재하는지 확인**

Run:
```bash
grep -c "kr.stadia.ruby-news" ruby-news.xcodeproj/project.pbxproj
grep -c "IPHONEOS_DEPLOYMENT_TARGET = 26.4" ruby-news.xcodeproj/project.pbxproj
grep -c "hotwire-native-ios" ruby-news.xcodeproj/project.pbxproj
grep -c "WeTransfer/Mocker" ruby-news.xcodeproj/project.pbxproj
grep -c "Signing.xcconfig" ruby-news.xcodeproj/project.pbxproj
grep -c "SwiftLint" ruby-news.xcodeproj/project.pbxproj
```
Expected: 모든 값 ≥ 1 (bundle id는 3타깃이라 ≥ 3). 하나라도 0이면 project.yml 교정.

- [ ] **Step 3: 5개 패키지 URL 모두 존재 확인**

Run:
```bash
for u in hotwire-native-ios SDWebImageSwiftUI KeychainAccess realm/SwiftLint WeTransfer/Mocker; do
  printf "%s: " "$u"; grep -c "$u" ruby-news.xcodeproj/project.pbxproj
done
```
Expected: 각 항목 ≥ 1.

- [ ] **Step 4: 이 Task는 커밋 없음**

`.xcodeproj`는 Task 5에서 gitignore + 추적 해제한다. 여기서는 커밋하지 않는다.

---

### Task 4: 빌드 및 테스트로 동등성 검증

**Files:**
- 없음 (검증 단계)

**Interfaces:**
- Consumes: Task 3이 생성한 `ruby-news.xcodeproj`.
- Produces: 생성된 프로젝트가 빌드/테스트를 통과한다는 확인.

- [ ] **Step 1: 빌드**

Run:
```bash
xcodebuild -project ruby-news.xcodeproj -scheme ruby-news \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```
Expected: `** BUILD SUCCEEDED **`.
SwiftLint 플러그인이 처음으로 실제 동작하므로 기존에 없던 lint 경고가 나올 수 있음 —
경고는 허용, 에러(빌드 실패)면 `.swiftlint.yml` 규칙 위반이 실제로 있는지 확인 후 대응.

- [ ] **Step 2: 테스트**

Run:
```bash
xcodebuild -project ruby-news.xcodeproj -scheme ruby-news \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```
Expected: `** TEST SUCCEEDED **`. 유닛/UI 테스트 모두 통과.

- [ ] **Step 3: 실패 시 대응, 성공 시 다음 Task**

빌드/테스트가 실패하면 원인을 project.yml 설정 누락으로 좁혀 Task 2를 교정하고 Task 3~4를 재실행한다.
이 Task는 커밋 없음.

---

### Task 5: .xcodeproj Git 추적 해제 및 gitignore

**Files:**
- Modify: `.gitignore`

**Interfaces:**
- Consumes: Task 4로 검증된 생성 프로젝트.
- Produces: `.xcodeproj`가 ignored 상태이며 로컬 파일은 보존됨.

- [ ] **Step 1: .gitignore에 xcodeproj 추가**

`.gitignore`의 `### Swift / Xcode` 섹션 아래에 다음 블록을 추가:

```
# XcodeGen — .xcodeproj is generated from project.yml
ruby-news.xcodeproj/
```

- [ ] **Step 2: Git 추적에서 제거 (로컬 파일 보존)**

Run:
```bash
git rm -r --cached ruby-news.xcodeproj
```
Expected: `rm 'ruby-news.xcodeproj/...'` 여러 줄 출력. 로컬 디렉터리는 그대로 남음.

- [ ] **Step 3: ignore 적용 확인**

Run:
```bash
git status --porcelain ruby-news.xcodeproj | head
git check-ignore ruby-news.xcodeproj/project.pbxproj
```
Expected: 첫 명령은 출력 없음(추적/미추적 변경으로 안 잡힘), 둘째 명령은 경로를 그대로 출력(ignored).

- [ ] **Step 4: 커밋**

```bash
git add .gitignore
git commit -m "chore: stop tracking generated xcodeproj, ignore it"
```

---

### Task 6: 문서 업데이트 (CLAUDE.md / AGENTS.md)

**Files:**
- Modify: `CLAUDE.md` (Commands 섹션)
- Modify: `AGENTS.md` (§5 Documentation 인근, 필요 시)

**Interfaces:**
- Consumes: 전체 전환 결과.
- Produces: 빌드 전 `xcodegen generate`가 필요함을 문서에 반영.

> 참고: 아래 Step 1~2의 제안 문안은 한국어로 작성되어 있으나, 실제 커밋된
> `CLAUDE.md`/`AGENTS.md` 추가분은 영어 문안으로 반영되었고 내용도 일부 정제됨.
> 이 계획의 문안은 취지 참고용이며, 최종 기준은 커밋된 문서 기준.

- [ ] **Step 1: CLAUDE.md Commands 섹션에 사전 단계 추가**

`## Commands` 섹션 상단(빌드 코드블록 직전)에 다음 안내를 추가:

~~~~markdown
프로젝트 파일은 XcodeGen으로 생성한다. `ruby-news.xcodeproj`는 git 추적되지 않으며
`project.yml`이 단일 소스다. 클론 직후 또는 `project.yml` 변경 후 반드시 실행:

```sh
# 최초 1회: XcodeGen 설치 및 로컬 서명 설정
brew install xcodegen
cp Config/Signing.xcconfig.example Config/Signing.xcconfig  # 팀 ID 기입

# 프로젝트 생성 (project.yml 변경 시마다)
xcodegen generate
```
~~~~

- [ ] **Step 2: AGENTS.md에 XcodeGen 규칙 한 줄 추가**

`AGENTS.md` §5 "Documentation" 목록 위 또는 프로젝트 규칙 안에 다음을 추가:

```markdown
- 프로젝트 구조/타깃/패키지 변경은 `.xcodeproj`가 아니라 `project.yml`을 수정한 뒤
  `xcodegen generate`로 반영한다. `.xcodeproj`는 생성물이며 git 추적하지 않는다.
```

- [ ] **Step 3: 문서 정합성 확인**

Run:
```bash
grep -n "xcodegen generate" CLAUDE.md AGENTS.md
```
Expected: 두 파일 모두에서 매칭 라인 출력.

- [ ] **Step 4: 커밋**

```bash
git add CLAUDE.md AGENTS.md
git commit -m "docs: document XcodeGen generate workflow"
```

---

## Self-Review

**Spec coverage:**
- project.yml 작성 → Task 2 ✓
- .xcodeproj gitignore + 추적 해제 → Task 5 ✓
- SwiftLint 빌드 플러그인 연결 → Task 2 Step 1 (`plugin: SwiftLintBuildToolPlugin`) ✓
- 문서에 `xcodegen generate` 반영 → Task 6 ✓
- Signing.xcconfig 셋업 안내 → Task 6 Step 1 ✓
- 검증 기준(설치→generate→build→test→값 대조→ignored) → Task 1~5 전반 ✓
- 패키지 5개 URL/버전/의존성 → Global Constraints + Task 2/3 ✓

**Placeholder scan:** TBD/TODO 없음. 모든 코드/커맨드/기대 출력 명시.

**Type consistency:** 패키지명·bundle id·플러그인명(`SwiftLintBuildToolPlugin`)·경로가 Task 전반에서 일관.
플러그인 *이름*은 일관하나, *부착 구문*은 구현 중 `dependencies:` 아래 `plugin:` 키에서
별도의 `buildToolPlugins:` 블록으로 정제되었다(위 Task 2 Step 1 참고).
