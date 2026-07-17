#!/bin/bash
# PostToolUse hook: ruby-news/ 아래 Swift 파일을 편집하면 SwiftLint로 즉시 검사한다.
# SwiftLint가 빌드 플러그인이라 위반이 빌드까지 가야 드러나는 문제를 앞당겨 잡는다.
# 비차단(advisory): 위반이 있어도 편집을 막지 않고 Claude에게 컨텍스트로만 전달한다.
set -euo pipefail

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')

[[ -n "${file_path:-}" ]] || exit 0
# ruby-news/ 소스만 대상. 테스트/UI테스트는 .swiftlint.yml에서 제외되므로 스킵.
case "$file_path" in
  */ruby-news/*.swift) : ;;
  *) exit 0 ;;
esac
case "$file_path" in
  */ruby-newsTests/*|*/ruby-newsUITests/*) exit 0 ;;
esac
[[ -f "$file_path" ]] || exit 0

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# swiftlint 바이너리 탐색: PATH 우선, 없으면 SwiftPM 플러그인 아티팩트에서 최신본 사용.
swiftlint_bin="$(command -v swiftlint 2>/dev/null || true)"
if [[ -z "$swiftlint_bin" ]]; then
  swiftlint_bin="$(find "$HOME/Library/Developer/Xcode/DerivedData" \
    -ipath '*artifacts/swiftlint/SwiftLintBinary/*/macos/swiftlint' -type f 2>/dev/null \
    | head -n 1)"
fi
[[ -n "$swiftlint_bin" && -x "$swiftlint_bin" ]] || exit 0

cd "$repo_root"
report=$("$swiftlint_bin" lint --quiet --config .swiftlint.yml "$file_path" 2>/dev/null || true)

[[ -n "$report" ]] || exit 0

msg=$(printf 'SwiftLint 위반 (%s):\n%s' "$(basename "$file_path")" "$report" | jq -Rs .)
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":%s}}\n' "$msg"
exit 0
