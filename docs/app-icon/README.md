# App Icon variants

`R` 모노그램 — 그린 배경 + 흰 글자. 1024×1024 PNG.

| 파일 | 톤 | 비고 |
|---|---|---|
| `icon-a-neon-low.png` | A안 + 네온(약) — Noto Sans CJK KR Bold + 잔잔한 라디얼 글로우 + 미세 halo | **현재 채택**. `ruby-news/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` 가 이 시안의 사본입니다. |
| `icon-a-neon-mid.png` | A안 + 네온(중) — 더 밝은 highlight + 두꺼운 halo | 비교용 보관 |
| `icon-a-sans.png` | A안 — Noto Sans CJK KR Black, flat 배경 (`#16A571`) | 비교용 보관 |
| `icon-b-blackletter.png` | B안 — UnifrakturCook Bold, flat 배경 | 비교용 보관 |

## 재현

폰트는 `~/Library/Fonts/NotoSansCJKkr-{Bold,Black}.otf` 가 시스템에 설치되어 있어야 합니다. Blackletter 는 `UnifrakturCook-Bold.ttf` (Google Fonts OFL) 를 같은 디렉터리에 두었습니다.

```bash
python3 docs/app-icon/render.py
```

네 PNG 가 같은 디렉터리에 갱신됩니다. 채택 시안의 강도/색을 조정하려면 `render.py` 안의 `render_neon(... icon-a-neon-low.png ...)` 호출 인자(`inner` / `outer` / `halo_*`) 를 수정하고, 결과를 `ruby-news/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` 로 다시 복사하세요.

## iOS 18 변형

`Contents.json` 에는 `dark` / `tinted` 슬롯도 정의되어 있지만 현재는 비어 있습니다. 시스템이 light 아이콘을 fallback 으로 사용합니다. 추후 다크 / 틴트 전용 마스크가 필요하면 같은 모노그램을 1채널 흰색 마스크로 만들어 추가하면 됩니다.
