# Fonts

The production app loads **Noto Sans KR** from Google Fonts (weights 400 / 500 / 700) at runtime:

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet"
      href="https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;700&display=swap">
```

## Local files

| File | Family | Weight | Source |
|---|---|---|---|
| `NotoSansCJKkr-Medium.otf` | `Noto Sans CJK KR` | 500 (Medium) | Adobe / Google Noto CJK |

The local Medium weight is `@font-face`'d in `colors_and_type.css` and listed first in `--font-primary`:

```css
@font-face {
    font-family: "Noto Sans CJK KR";
    font-style: normal;
    font-weight: 500;
    font-display: swap;
    src: url("fonts/NotoSansCJKkr-Medium.otf") format("opentype");
}

--font-primary: "Noto Sans CJK KR", "Noto Sans KR", "Pretendard", -apple-system, BlinkMacSystemFont, sans-serif;
```

The local file covers weight 500 only; weights 400 and 700 continue to load from the Google Fonts CDN (`Noto Sans KR`) so all three production weights resolve. Both names are the same Noto CJK Korean family — the local file simply gives the brand-supplied subset offline coverage at the medium weight where most UI body / meta text renders.

## Substitution flag

`Noto Sans KR` (Google Fonts) and `Noto Sans CJK KR` (local OTF) are the same Noto CJK Korean source — no substitution. If you need a single offline-first family at all three weights, download Bold and Regular from <https://fonts.google.com/noto/specimen/Noto+Sans+KR> and add matching `@font-face` blocks.
