#!/usr/bin/env python3
"""Build stable, palette-matched hero sheets from the preserved source assets."""

from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
CHARACTERS = ROOT / "assets" / "characters"
WALK_SOURCE = CHARACTERS / "collector_walk_sheet_v2.png"
ACTION_SOURCE = CHARACTERS / "collector_actions_v1.png"
ATTACK_SOURCE = CHARACTERS / "collector_bag_hammer_attack_v2_packed.png"

WALK_OUTPUT = CHARACTERS / "collector_walk_sheet_v3_canonical.png"
ACTION_OUTPUT = CHARACTERS / "collector_actions_v2_canonical.png"
ATTACK_OUTPUT = CHARACTERS / "collector_bag_hammer_attack_v3_canonical.png"

ACTION_CELL = 256
ACTION_ANCHOR = (128, 232)
ALPHA_COMPONENT_THRESHOLD = 30


def load_rgba(path: Path) -> np.ndarray:
    return np.asarray(Image.open(path).convert("RGBA"), dtype=np.uint8).copy()


def save_rgba(pixels: np.ndarray, path: Path) -> None:
    Image.fromarray(pixels, mode="RGBA").save(path, optimize=True)


def palette_stats(pixels: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    rgb = pixels[:, :, :3].astype(np.float32)
    alpha = pixels[:, :, 3]
    spread = rgb.max(axis=2) - rgb.min(axis=2)
    saturated_red = (
        (rgb[:, :, 0] > rgb[:, :, 1] * 1.35)
        & (rgb[:, :, 0] > rgb[:, :, 2] * 1.6)
        & (rgb[:, :, 0] > 90)
    )
    sample = rgb[(alpha > 64) & (~saturated_red) & (spread < 140)]
    return sample.mean(axis=0), sample.std(axis=0)


def match_palette(pixels: np.ndarray, target: np.ndarray, strength: float) -> np.ndarray:
    """Match neutral character colors while preserving the saturated red quest can."""
    result = pixels.copy()
    source_mean, source_std = palette_stats(pixels)
    target_mean, target_std = palette_stats(target)
    rgb = pixels[:, :, :3].astype(np.float32)
    corrected = (rgb - source_mean) * (target_std / np.maximum(source_std, 1.0)) + target_mean
    corrected = rgb * (1.0 - strength) + corrected * strength

    spread = rgb.max(axis=2) - rgb.min(axis=2)
    saturated_red = (
        (rgb[:, :, 0] > rgb[:, :, 1] * 1.35)
        & (rgb[:, :, 0] > rgb[:, :, 2] * 1.6)
        & (rgb[:, :, 0] > 90)
    )
    apply_mask = (pixels[:, :, 3] > 0) & (~saturated_red) & (spread < 140)
    result[:, :, :3][apply_mask] = np.clip(corrected[apply_mask], 0, 255).astype(np.uint8)
    result[pixels[:, :, 3] == 0, :3] = 0
    return result


def connected_components(mask: np.ndarray) -> list[tuple[np.ndarray, np.ndarray]]:
    height, width = mask.shape
    visited = np.zeros_like(mask, dtype=bool)
    components: list[tuple[np.ndarray, np.ndarray]] = []
    for start_y, start_x in zip(*np.where(mask)):
        if visited[start_y, start_x]:
            continue
        queue = deque([(int(start_y), int(start_x))])
        visited[start_y, start_x] = True
        ys: list[int] = []
        xs: list[int] = []
        while queue:
            y, x = queue.pop()
            ys.append(y)
            xs.append(x)
            for delta_y in (-1, 0, 1):
                for delta_x in (-1, 0, 1):
                    next_y = y + delta_y
                    next_x = x + delta_x
                    if (
                        0 <= next_y < height
                        and 0 <= next_x < width
                        and mask[next_y, next_x]
                        and not visited[next_y, next_x]
                    ):
                        visited[next_y, next_x] = True
                        queue.append((next_y, next_x))
        if len(xs) >= 50:
            components.append((np.asarray(ys), np.asarray(xs)))
    return components


def pack_action_sheet(source: np.ndarray, canonical: np.ndarray) -> np.ndarray:
    components = connected_components(source[:, :, 3] > ALPHA_COMPONENT_THRESHOLD)
    if len(components) != 32:
        raise RuntimeError(f"Expected 32 action silhouettes, found {len(components)}")

    descriptors = []
    for ys, xs in components:
        descriptors.append(
            {
                "ys": ys,
                "xs": xs,
                "center_y": float(ys.mean()),
                "center_x": float(xs.mean()),
                "min_y": int(ys.min()),
                "max_y": int(ys.max()),
                "min_x": int(xs.min()),
                "max_x": int(xs.max()),
            }
        )
    descriptors.sort(key=lambda item: item["center_y"])
    rows = [descriptors[index : index + 4] for index in range(0, 32, 4)]
    for row in rows:
        row.sort(key=lambda item: item["center_x"])

    sheet = np.zeros((ACTION_CELL * 8, ACTION_CELL * 4, 4), dtype=np.uint8)
    palette_matched = match_palette(source, canonical, strength=0.72)
    for row_index, row in enumerate(rows):
        for column_index, item in enumerate(row):
            padding = 3
            left = max(0, item["min_x"] - padding)
            right = min(source.shape[1], item["max_x"] + padding + 1)
            top = max(0, item["min_y"] - padding)
            bottom = min(source.shape[0], item["max_y"] + padding + 1)
            frame = palette_matched[top:bottom, left:right].copy()

            # Remove pixels from another pose if padded bounding boxes ever overlap.
            ownership = np.zeros(frame.shape[:2], dtype=bool)
            ownership[item["ys"] - top, item["xs"] - left] = True
            for _ in range(3):
                expanded = ownership.copy()
                expanded[1:, :] |= ownership[:-1, :]
                expanded[:-1, :] |= ownership[1:, :]
                expanded[:, 1:] |= ownership[:, :-1]
                expanded[:, :-1] |= ownership[:, 1:]
                ownership = expanded
            frame[~ownership, 3] = 0
            frame[frame[:, :, 3] == 0, :3] = 0

            alpha = frame[:, :, 3].astype(np.float32) / 255.0
            used_y, used_x = np.where(alpha > 0.12)
            min_y = int(used_y.min())
            max_y = int(used_y.max())
            head_end = min(max_y, min_y + 72)
            head_alpha = alpha[min_y : head_end + 1]
            head_x_values = np.arange(frame.shape[1], dtype=np.float32)[None, :]
            alpha_sum = float(head_alpha.sum())
            head_center_x = (
                float((head_alpha * head_x_values).sum() / alpha_sum)
                if alpha_sum > 0.0
                else float(frame.shape[1]) * 0.5
            )

            paste_x = round(ACTION_ANCHOR[0] - head_center_x)
            paste_y = ACTION_ANCHOR[1] - max_y
            if (
                paste_x < 0
                or paste_y < 0
                or paste_x + frame.shape[1] > ACTION_CELL
                or paste_y + frame.shape[0] > ACTION_CELL
            ):
                raise RuntimeError(f"Action frame {column_index},{row_index} does not fit canonical cell")
            y_slice = slice(row_index * ACTION_CELL + paste_y, row_index * ACTION_CELL + paste_y + frame.shape[0])
            x_slice = slice(column_index * ACTION_CELL + paste_x, column_index * ACTION_CELL + paste_x + frame.shape[1])
            sheet[y_slice, x_slice] = frame
    return sheet


def main() -> None:
    walk = load_rgba(WALK_SOURCE)
    actions = load_rgba(ACTION_SOURCE)
    attack = load_rgba(ATTACK_SOURCE)

    # Runtime already addressed only this 3x4 area. Removing the unused trailing
    # row/column makes the canonical sheet exactly divisible by its frame grid.
    walk_canonical = walk[: 305 * 4, : 429 * 3].copy()
    walk_canonical[walk_canonical[:, :, 3] == 0, :3] = 0
    action_canonical = pack_action_sheet(actions, walk_canonical)
    attack_canonical = match_palette(attack, walk_canonical, strength=0.62)

    save_rgba(walk_canonical, WALK_OUTPUT)
    save_rgba(action_canonical, ACTION_OUTPUT)
    save_rgba(attack_canonical, ATTACK_OUTPUT)
    print(f"Wrote {WALK_OUTPUT.relative_to(ROOT)} {walk_canonical.shape[1]}x{walk_canonical.shape[0]}")
    print(f"Wrote {ACTION_OUTPUT.relative_to(ROOT)} {action_canonical.shape[1]}x{action_canonical.shape[0]}")
    print(f"Wrote {ATTACK_OUTPUT.relative_to(ROOT)} {attack_canonical.shape[1]}x{attack_canonical.shape[0]}")


if __name__ == "__main__":
    main()
