"""
Ruby-News 앱 아이콘 시안 렌더러.

세 시안을 docs/app-icon/ 안에 갱신합니다.

  - icon-a-sans.png        : A안 (flat) — Noto Sans CJK KR Black
  - icon-a-neon-low.png    : A안 + 네온(약) — Bold + 잔잔한 라디얼 글로우 (현재 채택)
  - icon-a-neon-mid.png    : A안 + 네온(중) — Bold + 더 밝은 highlight + 두꺼운 halo
  - icon-b-blackletter.png : B안 (flat) — UnifrakturCook Bold

폰트:
  - ~/Library/Fonts/NotoSansCJKkr-{Bold,Black}.otf 가 시스템에 있어야 합니다.
  - UnifrakturCook-Bold.ttf 는 같은 디렉터리에 함께 보관 (Google Fonts OFL).
"""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os

W = 1024
CENTER = (W / 2, W / 2)
WHITE = (255, 255, 255, 255)

NOTO_BLACK = os.path.expanduser("~/Library/Fonts/NotoSansCJKkr-Black.otf")
NOTO_BOLD = os.path.expanduser("~/Library/Fonts/NotoSansCJKkr-Bold.otf")
UNIFRAKTUR = os.path.join(os.path.dirname(__file__), "UnifrakturCook-Bold.ttf")
OUT = os.path.dirname(__file__)


def radial_background(size, inner, outer, falloff=0.78):
    base = Image.new("RGB", (size, size), outer)
    draw = ImageDraw.Draw(base)
    steps = 96
    max_r = size * falloff
    for i in range(steps, 0, -1):
        t = i / steps
        r = max_r * t
        f = t ** 2
        c = tuple(int(outer[k] + (inner[k] - outer[k]) * f) for k in range(3))
        draw.ellipse(
            [size / 2 - r, size / 2 - r, size / 2 + r, size / 2 + r],
            fill=c,
        )
    return base.filter(ImageFilter.GaussianBlur(radius=18)).convert("RGBA")


def text_mask(font_path, font_size, y_nudge=0):
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    font = ImageFont.truetype(font_path, font_size)
    draw.text(
        (CENTER[0], CENTER[1] + y_nudge),
        "R",
        font=font,
        fill=WHITE,
        anchor="mm",
    )
    return img


def attenuate(img, factor):
    r, g, b, a = img.split()
    a = a.point(lambda p: min(255, int(p * factor)))
    return Image.merge("RGBA", (r, g, b, a))


def render_neon(font_path, font_size, out_path, *, inner, outer,
                halo_close_blur, halo_close_factor,
                halo_far_blur, halo_far_factor, y_nudge=0):
    bg = radial_background(W, inner, outer)
    sharp = text_mask(font_path, font_size, y_nudge=y_nudge)

    halo_close = attenuate(
        sharp.filter(ImageFilter.GaussianBlur(radius=halo_close_blur)),
        halo_close_factor,
    )
    halo_far = attenuate(
        sharp.filter(ImageFilter.GaussianBlur(radius=halo_far_blur)),
        halo_far_factor,
    )

    composite = bg.copy()
    composite = Image.alpha_composite(composite, halo_far)
    composite = Image.alpha_composite(composite, halo_close)
    composite = Image.alpha_composite(composite, sharp)
    composite.convert("RGB").save(out_path)
    print(f"wrote {out_path}")


def render_flat(font_path, font_size, out_path, *, bg=(0x16, 0xA5, 0x71), y_nudge=0):
    img = Image.new("RGB", (W, W), bg)
    draw = ImageDraw.Draw(img)
    font = ImageFont.truetype(font_path, font_size)
    draw.text(
        (CENTER[0], CENTER[1] + y_nudge),
        "R",
        font=font,
        fill=(255, 255, 255),
        anchor="mm",
    )
    img.save(out_path)
    print(f"wrote {out_path}")


# A안 (flat) — Black weight
render_flat(NOTO_BLACK, 720, os.path.join(OUT, "icon-a-sans.png"))

# A안 + 네온(약) — 채택본
render_neon(
    NOTO_BOLD, 720,
    os.path.join(OUT, "icon-a-neon-low.png"),
    inner=(0x2E, 0xE0, 0x9F),
    outer=(0x0C, 0x5E, 0x40),
    halo_close_blur=14, halo_close_factor=0.55,
    halo_far_blur=46, halo_far_factor=0.40,
)

# A안 + 네온(중) — 비교용 보관
render_neon(
    NOTO_BOLD, 720,
    os.path.join(OUT, "icon-a-neon-mid.png"),
    inner=(0x39, 0xF5, 0xB0),
    outer=(0x07, 0x4A, 0x32),
    halo_close_blur=20, halo_close_factor=0.90,
    halo_far_blur=72, halo_far_factor=0.75,
)

# B안 (flat) — Blackletter
render_flat(UNIFRAKTUR, 900, os.path.join(OUT, "icon-b-blackletter.png"), y_nudge=-20)
