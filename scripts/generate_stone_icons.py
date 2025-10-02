
#!/usr/bin/env python3


from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

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
AA = 8
BLACK_WIDTH = 4
ACCENT_WIDTH = 3


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
CIRCLE_MASK = _downsample(_make_high_res_disk(BLACK_WIDTH + ACCENT_WIDTH))

rect_hi = Image.new("L", (CANVAS_SIZE * AA, CANVAS_SIZE * AA), 0)
draw_rect = ImageDraw.Draw(rect_hi)
draw_rect.rectangle(
	(
		LEFT_MARGIN * AA,
		TOP_MARGIN * AA,
		(CANVAS_SIZE - RIGHT_MARGIN) * AA - 1,
		(CANVAS_SIZE - BOTTOM_MARGIN) * AA - 1,
	),
	fill=255,
)
RECT_MASK = rect_hi.resize((CANVAS_SIZE, CANVAS_SIZE), RESAMPLE)
CIRCLE_MASK = ImageChops.multiply(CIRCLE_MASK, RECT_MASK)


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


def save_icon(base: str, content: Image.Image) -> None:
	alpha = ImageChops.multiply(content.split()[-1], RECT_MASK)
	content.putalpha(alpha)
	output_path = OUTPUT_DIR / f"{base}.tga"
	content.save(output_path)
	print(f"Saved {output_path}")


def main() -> None:
	if not PNG_SOURCES:
		print("No PNG sources found in UI/")
		return

	for base, path in PNG_SOURCES:
		with Image.open(path) as source:
			content = prepare_content(source)

		save_icon(base, content)


if __name__ == "__main__":
	main()
