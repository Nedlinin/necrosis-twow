#!/usr/bin/env python3

from __future__ import annotations

import colorsys
from pathlib import Path
from typing import Iterable, Sequence

from PIL import Image, ImageChops, ImageOps

try:
	RESAMPLE = Image.Resampling.LANCZOS
except AttributeError:
	RESAMPLE = Image.LANCZOS

OUTPUT_DIR = Path("UI")
PNG_SOURCES = sorted(
	(path.stem, path)
	for path in OUTPUT_DIR.glob("*.png")
)

REFERENCE_GREYSCALE = Path("UI/FirestoneButton-02.tga")
REFERENCE_COLORED = Path("UI/FirestoneButton-03.tga")

UNIQUE_RATIO_THRESHOLD = 0.35
ALPHA_THRESHOLD = 10


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
		return (140, 140, 140)
	channels = list(zip(*filtered))
	means = [trimmed_mean(channel) for channel in channels]
	r, g, b = [max(0, min(255, int(round(value)))) for value in means]
	h, l, s = colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)
	l = max(0.28, min(0.62, l))
	s = max(0.20, min(0.75, s))
	r, g, b = colorsys.hls_to_rgb(h, l, s)
	return (
		max(0, min(255, int(round(r * 255)))),
		max(0, min(255, int(round(g * 255)))),
		max(0, min(255, int(round(b * 255)))),
	)


def detect_square_border(rgba: Image.Image) -> tuple[int, int, int, int]:
	width, height = rgba.size
	pixels = rgba.load()
	unique_threshold = max(12, int(width * UNIQUE_RATIO_THRESHOLD))

	def row_unique(y: int) -> int:
		colors = set()
		for x in range(width):
			r, g, b, a = pixels[x, y]
			if a <= ALPHA_THRESHOLD:
				continue
			colors.add((r, g, b))
			if len(colors) > unique_threshold:
				break
		return len(colors)

	def col_unique(x: int) -> int:
		colors = set()
		for y in range(height):
			r, g, b, a = pixels[x, y]
			if a <= ALPHA_THRESHOLD:
				continue
			colors.add((r, g, b))
			if len(colors) > unique_threshold:
				break
		return len(colors)

	top = 0
	for y in range(height // 2):
		if row_unique(y) > unique_threshold:
			top = y
			break
	bottom = 0
	for y in range(height - 1, height // 2 - 1, -1):
		if row_unique(y) > unique_threshold:
			bottom = height - 1 - y
			break
	left = 0
	for x in range(width // 2):
		if col_unique(x) > unique_threshold:
			left = x
			break
	right = 0
	for x in range(width - 1, width // 2 - 1, -1):
		if col_unique(x) > unique_threshold:
			right = width - 1 - x
			break
	return top, right, bottom, left


def remove_square_border(rgba: Image.Image) -> Image.Image:
	top, right, bottom, left = detect_square_border(rgba)
	width, height = rgba.size
	crop_box = (
		left,
		top,
		width - right,
		height - bottom,
	)
	if crop_box[0] >= crop_box[2] or crop_box[1] >= crop_box[3]:
		return rgba
	return rgba.crop(crop_box)


def load_reference_assets() -> tuple[Image.Image, Image.Image, Image.Image, Image.Image, Image.Image, tuple[float, float, float]]:
	ref_gray = Image.open(REFERENCE_GREYSCALE).convert("RGBA")
	ref_color = Image.open(REFERENCE_COLORED).convert("RGBA")
	if ref_gray.size != ref_color.size:
		raise ValueError("Reference ring variants must share the same dimensions")
	alpha = ref_gray.split()[-1]
	diff = ImageChops.difference(ref_gray, ref_color).convert("L")
	ring_mask = Image.new("L", ref_gray.size, 0)
	ring_pixels = ring_mask.load()
	diff_pixels = diff.load()
	alpha_pixels = alpha.load()
	width, height = ref_gray.size
	for y in range(height):
		for x in range(width):
			if diff_pixels[x, y] > 0:
				ring_pixels[x, y] = alpha_pixels[x, y]
	content_mask = ImageChops.subtract(alpha, ring_mask)
	ring_grey = Image.new("RGBA", ref_gray.size, (0, 0, 0, 0))
	ring_grey.paste(ref_gray, (0, 0), ring_mask)
	ring_color_template = Image.new("RGBA", ref_gray.size, (0, 0, 0, 0))
	ring_color_template.paste(ref_color, (0, 0), ring_mask)
	ring_values = [
		ring_color_template.getpixel((x, y))[:3]
		for y in range(height)
		for x in range(width)
		if ring_mask.getpixel((x, y))
	]
	if not ring_values:
		raise ValueError("Failed to isolate the reference ring pixels")
	ring_average = tuple(
		sum(value[index] for value in ring_values) / len(ring_values)
		for index in range(3)
	)
	return alpha, ring_mask, content_mask, ring_grey, ring_color_template, ring_average


(
	BASE_ALPHA,
	RING_MASK,
	CONTENT_MASK,
	RING_GREY,
	RING_COLOR_TEMPLATE,
	RING_COLOR_AVG,
) = load_reference_assets()
SIZE = RING_GREY.width
CONTENT_BBOX = CONTENT_MASK.getbbox()
if CONTENT_BBOX is None:
	raise ValueError("Reference content mask is empty")
CONTENT_DIAMETER = min(
	CONTENT_BBOX[2] - CONTENT_BBOX[0],
	CONTENT_BBOX[3] - CONTENT_BBOX[1],
)
CONTENT_CENTER = (
	(CONTENT_BBOX[0] + CONTENT_BBOX[2]) // 2,
	(CONTENT_BBOX[1] + CONTENT_BBOX[3]) // 2,
)
BLACK_BACKDROP = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
BLACK_BACKDROP.putalpha(BASE_ALPHA)


def prepare_content(image: Image.Image) -> Image.Image:
	rgba = remove_square_border(image.convert("RGBA"))
	alpha = rgba.split()[-1]
	bbox = alpha.getbbox()
	if not bbox:
		raise ValueError("Source image has no opaque pixels")
	content = rgba.crop(bbox)
	scale_limit = CONTENT_DIAMETER / max(content.size)
	scale = min(1.0, scale_limit)
	scale = max(scale, 0.5)
	if scale < 0.999:
		resized = (
			max(1, int(round(content.width * scale))),
			max(1, int(round(content.height * scale))),
		)
		content = content.resize(resized, RESAMPLE)
	canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
	offset = (
		CONTENT_CENTER[0] - content.width // 2,
		CONTENT_CENTER[1] - content.height // 2,
	)
	canvas.paste(content, offset, content)
	alpha_channel = canvas.split()[-1]
	alpha_channel = ImageChops.multiply(alpha_channel, CONTENT_MASK)
	canvas.putalpha(alpha_channel)
	return canvas


def to_grayscale(image: Image.Image) -> Image.Image:
	rgb = image.convert("RGB")
	alpha = image.split()[-1]
	gray = ImageOps.grayscale(rgb)
	return Image.merge("RGBA", (gray, gray, gray, alpha))


def build_accent_ring(target_rgb: tuple[int, int, int]) -> Image.Image:
	scales = []
	for index, reference in enumerate(RING_COLOR_AVG):
		ref_value = max(reference, 1.0)
		scales.append(target_rgb[index] / ref_value)
	result = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
	res_pixels = result.load()
	template_pixels = RING_COLOR_TEMPLATE.load()
	mask_pixels = RING_MASK.load()
	for y in range(SIZE):
		for x in range(SIZE):
			alpha = mask_pixels[x, y]
			if not alpha:
				continue
			src_r, src_g, src_b, _ = template_pixels[x, y]
			new_r = max(0, min(255, int(round(src_r * scales[0]))))
			new_g = max(0, min(255, int(round(src_g * scales[1]))))
			new_b = max(0, min(255, int(round(src_b * scales[2]))))
			res_pixels[x, y] = (new_r, new_g, new_b, alpha)
	return result


def save_variant(base: str, suffix: str, content: Image.Image, ring_overlay: Image.Image) -> None:
	combined = Image.alpha_composite(Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0)), content)
	combined = Image.alpha_composite(combined, ring_overlay)
	combined_alpha = ImageChops.multiply(combined.split()[-1], BASE_ALPHA)
	combined.putalpha(combined_alpha)
	final_image = Image.alpha_composite(BLACK_BACKDROP, combined)
	output_path = OUTPUT_DIR / f"{base}{suffix}.tga"
	final_image.save(output_path)
	print(f"Saved {output_path}")


def main() -> None:
	if not PNG_SOURCES:
		print("No PNG sources found in UI/")
		return
	for base, path in PNG_SOURCES:
		if not path.exists():
			print(f"Skipping {path} (missing)")
			continue
		with Image.open(path) as source:
			content = prepare_content(source)
		content_pixels = [px[:3] for px in content.getdata() if px[3] > 0]
		accent_color = compute_ring_color(content_pixels)
		grayscale_content = to_grayscale(content)
		save_variant(base, "-01", grayscale_content, RING_GREY)
		save_variant(base, "-02", content.copy(), RING_GREY)
		accent_ring = build_accent_ring(accent_color)
		save_variant(base, "-03", content.copy(), accent_ring)


if __name__ == "__main__":
	main()
