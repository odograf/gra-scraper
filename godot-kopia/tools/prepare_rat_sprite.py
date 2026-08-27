#!/usr/bin/env python3
"""Extract, clean and anchor the generated Szczór sheet without another render."""

from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "animals" / "sewer_rat_sheet_v1_generated_source.png"
OUTPUT = ROOT / "assets" / "animals" / "sewer_rat_sheet_v1.png"
CELL = (512, 384)
GRID = (4, 4)
ANCHOR = (256, 330)


def components(mask: np.ndarray) -> list[tuple[np.ndarray, np.ndarray]]:
    height, width = mask.shape
    seen = np.zeros_like(mask, dtype=bool)
    result: list[tuple[np.ndarray, np.ndarray]] = []
    for start_y, start_x in zip(*np.where(mask)):
        if seen[start_y, start_x]:
            continue
        queue = [(int(start_y), int(start_x))]
        seen[start_y, start_x] = True
        ys: list[int] = []
        xs: list[int] = []
        while queue:
            y, x = queue.pop()
            ys.append(y)
            xs.append(x)
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    ny, nx = y + dy, x + dx
                    if (
                        0 <= ny < height
                        and 0 <= nx < width
                        and mask[ny, nx]
                        and not seen[ny, nx]
                    ):
                        seen[ny, nx] = True
                        queue.append((ny, nx))
        if len(xs) > 100:
            result.append((np.asarray(ys), np.asarray(xs)))
    return result


def dilate(mask: np.ndarray, steps: int) -> np.ndarray:
    expanded = mask.copy()
    for _ in range(steps):
        previous = expanded.copy()
        expanded[1:, :] |= previous[:-1, :]
        expanded[:-1, :] |= previous[1:, :]
        expanded[:, 1:] |= previous[:, :-1]
        expanded[:, :-1] |= previous[:, 1:]
        expanded[1:, 1:] |= previous[:-1, :-1]
        expanded[:-1, :-1] |= previous[1:, 1:]
        expanded[1:, :-1] |= previous[:-1, 1:]
        expanded[:-1, 1:] |= previous[1:, :-1]
    return expanded


def fill_enclosed_holes(mask: np.ndarray) -> np.ndarray:
    height, width = mask.shape
    outside = np.zeros_like(mask, dtype=bool)
    queue: deque[tuple[int, int]] = deque()
    for x in range(width):
        if not mask[0, x]:
            outside[0, x] = True
            queue.append((0, x))
        if not mask[height - 1, x]:
            outside[height - 1, x] = True
            queue.append((height - 1, x))
    for y in range(height):
        if not mask[y, 0]:
            outside[y, 0] = True
            queue.append((y, 0))
        if not mask[y, width - 1]:
            outside[y, width - 1] = True
            queue.append((y, width - 1))
    while queue:
        y, x = queue.popleft()
        for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < height and 0 <= nx < width and not mask[ny, nx] and not outside[ny, nx]:
                outside[ny, nx] = True
                queue.append((ny, nx))
    return ~outside


def extract_frame(rgb: np.ndarray, ys: np.ndarray, xs: np.ndarray) -> np.ndarray:
    padding = 7
    left = max(0, int(xs.min()) - padding)
    right = min(rgb.shape[1], int(xs.max()) + padding + 1)
    top = max(0, int(ys.min()) - padding)
    bottom = min(rgb.shape[0], int(ys.max()) + padding + 1)
    crop = rgb[top:bottom, left:right].copy()

    owned_core = np.zeros(crop.shape[:2], dtype=bool)
    owned_core[ys - top, xs - left] = True
    owned_core = fill_enclosed_holes(owned_core)
    edge_zone = dilate(owned_core, 3)

    minimum = crop.min(axis=2).astype(np.float32)
    spread = (crop.max(axis=2) - crop.min(axis=2)).astype(np.float32)
    # The generated RGB source contains a pale checkerboard and a light matte.
    # Only dark or distinctly colored edge pixels receive alpha; this removes
    # the white halo without punching holes in enclosed teeth or eyes.
    soft_alpha = np.maximum((180.0 - minimum) / 25.0, (spread - 25.0) / 30.0)
    soft_alpha = np.clip(soft_alpha, 0.0, 1.0)
    alpha = np.zeros(crop.shape[:2], dtype=np.uint8)
    alpha[edge_zone] = (soft_alpha[edge_zone] * 255.0).astype(np.uint8)
    alpha[owned_core] = 255

    rgba = np.zeros((crop.shape[0], crop.shape[1], 4), dtype=np.uint8)
    rgba[:, :, :3] = crop
    rgba[:, :, 3] = alpha
    rgba[alpha == 0, :3] = 0
    return rgba


def main() -> None:
    source = np.asarray(Image.open(SOURCE).convert("RGB"), dtype=np.uint8)
    minimum = source.min(axis=2)
    spread = source.max(axis=2) - minimum
    core_mask = (minimum < 180) | (spread > 30)
    silhouettes = components(core_mask)
    if len(silhouettes) != 16:
        raise RuntimeError(f"Expected 16 rat silhouettes, found {len(silhouettes)}")

    descriptors = []
    for ys, xs in silhouettes:
        descriptors.append({"ys": ys, "xs": xs, "cy": float(ys.mean()), "cx": float(xs.mean())})
    descriptors.sort(key=lambda item: item["cy"])
    rows = [descriptors[index : index + 4] for index in range(0, 16, 4)]
    for row in rows:
        row.sort(key=lambda item: item["cx"])

    sheet = np.zeros((CELL[1] * GRID[1], CELL[0] * GRID[0], 4), dtype=np.uint8)
    for row_index, row in enumerate(rows):
        for column_index, item in enumerate(row):
            frame = extract_frame(source, item["ys"], item["xs"])
            visible = frame[:, :, 3] > 30
            used_y, used_x = np.where(visible)
            ground_y = int(used_y.max())

            # Alpha-weighted mass center follows the torso; the long thin tail
            # contributes little and therefore cannot jerk the whole sprite.
            weights = frame[:, :, 3].astype(np.float32) / 255.0
            x_values = np.arange(frame.shape[1], dtype=np.float32)[None, :]
            body_center_x = float((weights * x_values).sum() / weights.sum())
            paste_x = round(ANCHOR[0] - body_center_x)
            paste_y = ANCHOR[1] - ground_y
            if (
                paste_x < 0
                or paste_y < 0
                or paste_x + frame.shape[1] > CELL[0]
                or paste_y + frame.shape[0] > CELL[1]
            ):
                raise RuntimeError(f"Rat frame {column_index},{row_index} does not fit its cell")
            y0 = row_index * CELL[1] + paste_y
            x0 = column_index * CELL[0] + paste_x
            sheet[y0 : y0 + frame.shape[0], x0 : x0 + frame.shape[1]] = frame

    Image.fromarray(sheet, mode="RGBA").save(OUTPUT, optimize=True)
    print(f"Wrote {OUTPUT.relative_to(ROOT)}: {sheet.shape[1]}x{sheet.shape[0]}, anchor={ANCHOR}")


if __name__ == "__main__":
    main()
