
#!/usr/bin/env python3

from __future__ import annotations

import colorsys
from pathlib import Path
from typing import Iterable, Sequence

from PIL import Image, ImageChops, ImageDraw, ImageOps

try:
	RESAMPLE = Image.Resampling.LANCZOS
except AttributeError:
	RESAMPLE = Image.LANCZOS

OUTPUT_DIR = Path("UI")
PNG_SOURCES = sorted(
	(path.stem, path)
	for path in OUTPUT_DIR.glob("*.png")
	if path.stem.lower() != "accentringreference"
)

CANVAS_SIZE = 64
CONTENT_SIZE = 52
TOP_MARGIN = 5
BOTTOM_MARGIN = 5
LEFT_MARGIN = 4
RIGHT_MARGIN = 4
BLACK_WIDTH = 4
ACCENT_WIDTH = 3
AA = 8

NEUTRAL_RING_RGB = (168, 168, 168)


def trimmed_mean(values: Sequence[int], trim_ratio: float = 0.1) -> float:
	if not values:
		return 0.0
	sorted_vals = sorted(values)
	trim_fraction = max(0.0, min(trim_ratio, 0.5)) * 0.5
	trim = int(len(sorted_vals) * trim_fraction)
	if trim:
		sorted_vals = sorted_vals[trim:-trim]
	return sum(sorted_vals) / len(sorted_vals)


def compute_ring_color(pixels: Iterable[tuple[int, int, int]]) -> tuple[int, int, int]:
	filtered = [p for p in pixels if any(channel > 0 for channel in p)]
	if not filtered:
		return NEUTRAL_RING_RGB
	channels = list(zip(*filtered))
	means = [trimmed_mean(channel) for channel in channels]
	r, g, b = [max(0, min(255, int(round(value)))) for value in means]
	h, l, s = colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)
	l = max(0.30, min(0.62, l))
	s = max(0.25, min(0.75, s))
	r, g, b = colorsys.hls_to_rgb(h, l, s)
	return (
		max(0, min(255, int(round(r * 255)))),
		max(0, min(255, int(round(g * 255)))),
		max(0, min(255, int(round(b * 255)))),
	)


def _high_res_bounds(padding: float) -> tuple[int, int, int, int]:
	left = (LEFT_MARGIN + padding) * AA
	top = (TOP_MARGIN + padding) * AA
	right = (CANVAS_SIZE - RIGHT_MARGIN - padding) * AA - 2
	bottom = (CANVAS_SIZE - BOTTOM_MARGIN - padding) * AA - 2
	return (
		int(round(left)),
		int(round(top)),
		int(round(right)),
		int(round(bottom)),
	)


def _make_high_res_disk(padding: float) -> Image.Image:
	size = CANVAS_SIZE * AA
	mask = Image.new("L", (size, size), 0)
	draw = ImageDraw.Draw(mask)
	draw.ellipse(_high_res_bounds(padding), fill=255)
	return mask


def _downsample(mask: Image.Image) -> Image.Image:
	return mask.resize((CANVAS_SIZE, CANVAS_SIZE), RESAMPLE)


# Prebuild masks at high resolution for crisp edges
_outer_hi = _make_high_res_disk(0)
_black_inner_hi = _make_high_res_disk(BLACK_WIDTH)
_accent_inner_hi = _make_high_res_disk(BLACK_WIDTH + ACCENT_WIDTH)
_circle_hi = _make_high_res_disk(BLACK_WIDTH + ACCENT_WIDTH)

BLACK_MASK = _downsample(ImageChops.subtract(_outer_hi, _black_inner_hi))
ACCENT_MASK = _downsample(ImageChops.subtract(_black_inner_hi, _accent_inner_hi))
CIRCLE_MASK = _downsample(_circle_hi)
FINAL_ALPHA_MASK = ImageChops.lighter(CIRCLE_MASK, ImageChops.lighter(ACCENT_MASK, BLACK_MASK))

rect_hi = Image.new("L", (CANVAS_SIZE * AA, CANVAS_SIZE * AA), 0)
draw_rect = ImageDraw.Draw(rect_hi)
draw_rect.rectangle((
	LEFT_MARGIN * AA,
	TOP_MARGIN * AA,
	(CANVAS_SIZE - RIGHT_MARGIN) * AA - 1,
	(CANVAS_SIZE - BOTTOM_MARGIN) * AA - 1,
), fill=255)
RECT_MASK = rect_hi.resize((CANVAS_SIZE, CANVAS_SIZE), RESAMPLE)

BLACK_MASK = ImageChops.multiply(BLACK_MASK, RECT_MASK)
ACCENT_MASK = ImageChops.multiply(ACCENT_MASK, RECT_MASK)
CIRCLE_MASK = ImageChops.multiply(CIRCLE_MASK, RECT_MASK)
FINAL_ALPHA_MASK = ImageChops.multiply(FINAL_ALPHA_MASK, RECT_MASK)


def prepare_content(image: Image.Image) -> Image.Image:
	resized = image.convert("RGBA").resize((CONTENT_SIZE, CONTENT_SIZE), RESAMPLE)
	canvas = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
	offset = (
		(CANVAS_SIZE - CONTENT_SIZE) // 2,
		(CANVAS_SIZE - CONTENT_SIZE) // 2,
	)
	canvas.paste(resized, offset, resized)
	alpha = canvas.split()[-1]
	alpha = ImageChops.multiply(alpha, CIRCLE_MASK)
	canvas.putalpha(alpha)
	return canvas


def to_grayscale(image: Image.Image) -> Image.Image:
	rgb = image.convert("RGB")
	alpha = image.split()[-1]
	gray = ImageOps.grayscale(rgb)
	return Image.merge("RGBA", (gray, gray, gray, alpha))


def build_ring(accent_rgb: tuple[int, int, int]) -> Image.Image:
	ring = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
	black_ring = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 255))
	black_ring.putalpha(BLACK_MASK)
	ring = Image.alpha_composite(ring, black_ring)
	accent = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), accent_rgb + (255,))
	accent.putalpha(ACCENT_MASK)
	ring = Image.alpha_composite(ring, accent)
	return ring


def save_variant(base: str, suffix: str, content: Image.Image, ring_rgb: tuple[int, int, int]) -> None:
	ring = build_ring(ring_rgb)
	combined = Image.alpha_composite(content, ring)
	combined_alpha = ImageChops.multiply(combined.split()[-1], FINAL_ALPHA_MASK)
	combined.putalpha(combined_alpha)
	combined = Image.composite(combined, Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0)), FINAL_ALPHA_MASK)
	px = combined.load()
	for y in range(CANVAS_SIZE):
		for x in range(CANVAS_SIZE):
			if x < LEFT_MARGIN or x > CANVAS_SIZE - RIGHT_MARGIN - 1 or y < TOP_MARGIN or y > CANVAS_SIZE - BOTTOM_MARGIN - 1:
				px[x, y] = (0, 0, 0, 0)
	output_path = OUTPUT_DIR / f"{base}{suffix}.tga"
	combined.save(output_path)
	print(f"Saved {output_path}")


def main() -> None:
	if not PNG_SOURCES:
		print("No PNG sources found in UI/")
		return

	for base, path in PNG_SOURCES:
		with Image.open(path) as source:
			content = prepare_content(source)

		pixels = [px[:3] for px in content.getdata() if px[3] > 0]
		accent_rgb = compute_ring_color(pixels)

		save_variant(base, "-01", to_grayscale(content), NEUTRAL_RING_RGB)
		save_variant(base, "-02", content.copy(), NEUTRAL_RING_RGB)
		save_variant(base, "-03", content.copy(), accent_rgb)


if __name__ == "__main__":
	main()
