#!/bin/bash
# PostToolUse hook: project.yml을 수정하면 XcodeGen 프로젝트를 자동 재생성한다.
# project.yml이 단일 소스이고 .xcodeproj는 비추적이라, 재생성을 잊으면
# stale한 프로젝트로 빌드가 돌아간다. 이 hook가 그 실수를 없앤다.
set -euo pipefail

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')

# project.yml 편집일 때만 동작
[[ "$(basename "${file_path:-}")" == "project.yml" ]] || exit 0

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

command -v xcodegen >/dev/null 2>&1 || {
  echo '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"project.yml이 변경됐지만 xcodegen이 PATH에 없어 재생성을 건너뜀. `brew install xcodegen` 후 `xcodegen generate` 실행 필요."}}'
  exit 0
}

if out=$(xcodegen generate 2>&1); then
  echo '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"project.yml 변경 감지 → xcodegen generate 완료. ruby-news.xcodeproj가 갱신됐다."}}'
else
  msg=$(printf 'xcodegen generate 실패:\n%s' "$out" | jq -Rs .)
  printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":%s}}\n' "$msg"
fi
exit 0
