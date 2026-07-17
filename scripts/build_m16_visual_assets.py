#!/usr/bin/env python3
"""Build deterministic, project-original one-bit M16 production atlases."""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
import sys
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/art/production"
SCRIPT_PATH = "scripts/build_m16_visual_assets.py"
BLACK = (0, 0, 0, 255)
WHITE = (255, 255, 255, 255)
CLEAR = (0, 0, 0, 0)
ALLOWED = {BLACK, WHITE, CLEAR}

CHARACTERS = (
    "reimu_hakurei", "marisa_kirisame", "sakuya_izayoi", "remilia_scarlet",
    "youmu_konpaku", "aya_shameimaru", "sanae_kochiya", "tenshi_hinanawi",
)
REGIONS = (
    "hakurei_shrine", "scarlet_devil_mansion", "youkai_mountain",
    "eientei_bamboo_forest", "hakugyokurou",
)
FIGHTER_ACTIONS = (
    "idle", "crouch", "walk_forward", "walk_back", "jump", "air_dash",
    "ground_dash", "guard_high", "guard_low", "throw", "normal_1",
    "normal_2", "normal_3", "normal_4", "normal_5", "command_normal_1",
    "command_normal_2", "special_1", "special_2", "special_3", "special_4",
    "spell_1", "spell_2", "hit", "down", "win", "surrender",
    "focus_cancel", "spell_declaration",
)
PORTRAIT_EXPRESSIONS = (
    "work_neutral", "social_neutral", "amused", "irritated", "focused",
    "startled", "tired_private", "sincere_restrained", "route_vulnerable",
)
BULLETS = (
    "amulet", "needle", "orb", "star", "knife", "butterfly", "leaf",
    "arrow", "shard", "plate", "spirit", "keystone_chip",
)


class Canvas:
    def __init__(self, width: int, height: int) -> None:
        self.width, self.height = width, height
        self.pixels = [CLEAR] * (width * height)

    def set(self, x: int, y: int, color=BLACK) -> None:
        if color not in ALLOWED:
            raise ValueError(f"non-one-bit color: {color}")
        if 0 <= x < self.width and 0 <= y < self.height:
            self.pixels[y * self.width + x] = color

    def rect(self, x: int, y: int, w: int, h: int, color=BLACK) -> None:
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.set(xx, yy, color)

    def stroke(self, x: int, y: int, w: int, h: int, color=BLACK, t: int = 1) -> None:
        self.rect(x, y, w, t, color); self.rect(x, y + h - t, w, t, color)
        self.rect(x, y, t, h, color); self.rect(x + w - t, y, t, h, color)

    def line(self, x0: int, y0: int, x1: int, y1: int, color=BLACK, t: int = 1) -> None:
        dx, sx = abs(x1 - x0), 1 if x0 < x1 else -1
        dy, sy = -abs(y1 - y0), 1 if y0 < y1 else -1
        err = dx + dy
        while True:
            self.rect(x0 - (t - 1) // 2, y0 - (t - 1) // 2, t, t, color)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy: err += dy; x0 += sx
            if e2 <= dx: err += dx; y0 += sy

    def circle(self, cx: int, cy: int, r: int, color=BLACK, hollow: bool = False) -> None:
        for y in range(-r, r + 1):
            for x in range(-r, r + 1):
                d = x * x + y * y
                if d <= r * r and (not hollow or d >= (r - 1) * (r - 1)):
                    self.set(cx + x, cy + y, color)

    def poly(self, points: list[tuple[int, int]], color=BLACK) -> None:
        lo, hi = min(y for _, y in points), max(y for _, y in points)
        for y in range(lo, hi + 1):
            nodes = []
            j = len(points) - 1
            for i, (xi, yi) in enumerate(points):
                xj, yj = points[j]
                if (yi < y <= yj) or (yj < y <= yi):
                    nodes.append(round(xi + (y - yi) * (xj - xi) / (yj - yi)))
                j = i
            nodes.sort()
            for i in range(0, len(nodes) - 1, 2):
                self.rect(nodes[i], y, nodes[i + 1] - nodes[i] + 1, 1, color)

    def checker(self, x: int, y: int, w: int, h: int, period: int = 2) -> None:
        for yy in range(h):
            for xx in range(w):
                if (xx + yy) % period == 0:
                    self.set(x + xx, y + yy)

    def png(self) -> bytes:
        raw = bytearray()
        for y in range(self.height):
            raw.append(0)
            for pixel in self.pixels[y * self.width:(y + 1) * self.width]:
                raw.extend(pixel)
        def chunk(kind: bytes, payload: bytes) -> bytes:
            body = kind + payload
            return struct.pack(">I", len(payload)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)
        return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", self.width, self.height, 8, 6, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b""))


def _face(c: Canvas, x: int, y: int, scale: int = 1) -> None:
    c.rect(x - 2 * scale, y - scale, 5 * scale, 4 * scale, WHITE)
    c.set(x - scale, y, BLACK); c.set(x + scale, y, BLACK)


def _model_m(c: Canvas, ox: int, char: str, frame: int) -> None:
    phase = frame if frame < 4 else frame - 4 if frame < 12 else frame - 12
    bob = (-1 if frame in (1, 7, 9, 13) else 0)
    y = bob
    stride = (-2, -1, 0, 1, 2, 1, 0, -1)[phase % 8] if 4 <= frame < 12 else 0
    cx = ox + 12
    # Independently locked silhouettes; shared feet anchor remains (12,31).
    if char == "reimu_hakurei":
        c.circle(cx, y + 9, 4); _face(c, cx, y + 9)
        c.poly([(cx-3,y+5),(cx-8,y+2),(cx-7,y+8)]); c.poly([(cx+3,y+5),(cx+8,y+2),(cx+7,y+8)])
        c.poly([(cx-4,y+15),(cx+4,y+15),(cx+6,y+29),(cx-6,y+29)])
        c.rect(cx-9,y+16,4,8); c.rect(cx+6,y+16,4,8); c.rect(cx-2,y+20,4,2,WHITE)
        c.line(cx+8,y+17,cx+10,y+9-frame%2); c.line(cx+9,y+12,cx+12,y+12)
    elif char == "marisa_kirisame":
        c.poly([(cx-10,y+7),(cx+10,y+7),(cx+2,y+1),(cx-3,y+1)]); c.rect(cx-8,y+7,16,2)
        c.circle(cx,y+11,4); _face(c,cx,y+11)
        c.poly([(cx-4,y+16),(cx+4,y+16),(cx+7,y+29),(cx-7,y+29)]); c.poly([(cx-2,y+18),(cx+3,y+18),(cx+4,y+27),(cx-3,y+27)],WHITE)
        c.line(cx-10,y+27,cx+10,y+13-frame%3); c.line(cx-10,y+27,cx-7,y+30)
    elif char == "sakuya_izayoi":
        c.circle(cx,y+8,4); _face(c,cx,y+8); c.rect(cx-4,y+3,2,2,WHITE); c.rect(cx-1,y+2,2,2,WHITE); c.rect(cx+2,y+3,2,2,WHITE)
        c.poly([(cx-3,y+13),(cx+3,y+13),(cx+7,y+29),(cx-7,y+29)]); c.rect(cx-2,y+16,4,11,WHITE)
        for k in range(3): c.line(cx+5,y+16,cx+10,y+12+k*3-frame%2)
    elif char == "remilia_scarlet":
        c.circle(cx,y+9,3); _face(c,cx,y+9); c.rect(cx-4,y+4,8,2); c.set(cx+4,y+3)
        c.rect(cx-2,y+13,4,14); c.poly([(cx-2,y+15),(cx-10,y+10),(cx-8,y+23)]); c.poly([(cx+2,y+15),(cx+10,y+10),(cx+8,y+23)])
        c.line(cx+4,y+17,cx+10,y+7-frame%2); c.rect(cx+9,y+5,2,4)
    elif char == "youmu_konpaku":
        c.circle(cx,y+8,4); _face(c,cx,y+8); c.rect(cx-4,y+4,2,2)
        c.poly([(cx-3,y+13),(cx+3,y+13),(cx+5,y+28),(cx-5,y+28)])
        c.line(cx-5,y+25,cx+8,y+10-frame%2); c.line(cx-3,y+27,cx+10,y+18)
        c.circle(cx+8,y+22+(frame%2),3); c.circle(cx+10,y+24+(frame%2),1,WHITE)
    elif char == "aya_shameimaru":
        c.rect(cx-3,y+1,6,4); c.circle(cx,y+9,4); _face(c,cx,y+9)
        c.poly([(cx-3,y+14),(cx+3,y+14),(cx+5,y+28),(cx-5,y+28)])
        c.poly([(cx-3,y+16),(cx-10,y+12),(cx-7,y+25)]); c.stroke(cx+4,y+15,6,5); c.circle(cx+7,y+17,1)
    elif char == "sanae_kochiya":
        c.rect(cx-5,y+5,10,17); c.circle(cx,y+8,4); _face(c,cx,y+8)
        c.circle(cx-4,y+2,2,hollow=True); c.circle(cx+4,y+2,2,hollow=True)
        c.poly([(cx-3,y+14),(cx+3,y+14),(cx+6,y+29),(cx-6,y+29)]); c.rect(cx-9,y+16,5,7); c.rect(cx+5,y+16,5,7)
        c.line(cx+8,y+18,cx+10,y+8-frame%2); c.line(cx+8,y+11,cx+12,y+11)
    else:  # tenshi
        c.circle(cx,y+9,4); _face(c,cx,y+9); c.rect(cx-7,y+4,14,2); c.circle(cx,y+2,2)
        c.poly([(cx-3,y+14),(cx+4,y+14),(cx+6,y+29),(cx-5,y+29)])
        c.stroke(cx-10,y+18,6,6); c.line(cx+5,y+18,cx+10,y+5-frame%2,BLACK,2)
    if frame >= 12:
        # Four authored talk beats: closed, open, emphasis, and release. The
        # primary-hand cue is deliberately visible even when the mouth is tiny.
        talk = frame - 12
        head_y = y + (11 if char == "marisa_kirisame" else 9)
        c.rect(cx-2, head_y+2, 5, 2, WHITE)
        if talk == 0: c.line(cx-1,head_y+3,cx+1,head_y+3)
        elif talk == 1: c.rect(cx-1,head_y+2,3,2)
        elif talk == 2: c.line(cx-2,head_y+2,cx+2,head_y+3); c.line(cx+7,y+14,cx+11,y+10,BLACK,2)
        else: c.line(cx-1,head_y+2,cx+2,head_y+2); c.set(cx+8,y+13)
    c.rect(cx-4 + min(0,stride), y+29,3,2); c.rect(cx+2 + max(0,stride), y+29,3,2)


def model_m_sheet(char: str) -> Canvas:
    c = Canvas(384, 32)
    for frame in range(16):
        _model_m(c, frame * 24, char, frame)
    return c


def _model_l_down(c: Canvas, ox: int, char: str) -> None:
    """Draw a prone silhouette that preserves the character's identity cue."""
    # The body deliberately occupies most of the 32 px cell instead of becoming
    # a generic floor dash. The head is on the facing/right side of the source.
    c.poly([(ox+3,38),(ox+9,34),(ox+22,35),(ox+28,41),(ox+8,44)])
    c.circle(ox+25,34,5)
    c.rect(ox+2,41,11,3)
    c.rect(ox+20,40,10,3)
    _face(c,ox+25,34)
    if char == "reimu_hakurei":
        c.poly([(ox+22,30),(ox+13,24),(ox+15,34)])
        c.poly([(ox+27,30),(ox+31,24),(ox+31,35)])
        c.rect(ox+4,34,7,8)
    elif char == "marisa_kirisame":
        c.poly([(ox+14,31),(ox+31,31),(ox+22,21),(ox+18,27)])
        c.rect(ox+12,31,19,3)
        c.line(ox+2,44,ox+29,26,BLACK,2)
    elif char == "sakuya_izayoi":
        c.rect(ox+19,27,3,3,WHITE)
        c.rect(ox+24,25,3,3,WHITE)
        c.rect(ox+29,27,3,3,WHITE)
        c.rect(ox+8,36,4,7,WHITE)
        c.line(ox+2,32,ox+14,43,BLACK,2)
    elif char == "remilia_scarlet":
        c.poly([(ox+9,36),(ox+1,25),(ox+3,42)])
        c.poly([(ox+15,35),(ox+10,23),(ox+20,38)])
        c.rect(ox+21,27,10,3)
    elif char == "youmu_konpaku":
        c.line(ox+1,29,ox+30,43,BLACK,2)
        c.line(ox+3,44,ox+29,26,BLACK,2)
        c.circle(ox+7,31,5)
        c.circle(ox+5,29,2,WHITE)
    elif char == "aya_shameimaru":
        c.poly([(ox+10,37),(ox+1,25),(ox+4,43)])
        c.poly([(ox+16,36),(ox+10,24),(ox+20,41)])
        c.rect(ox+21,26,9,5)
    elif char == "sanae_kochiya":
        c.rect(ox+18,29,13,11)
        c.circle(ox+20,25,3,hollow=True)
        c.circle(ox+29,25,3,hollow=True)
        c.rect(ox+3,34,7,9)
    else:
        c.rect(ox+16,27,15,4)
        c.circle(ox+25,24,3)
        c.stroke(ox+2,30,10,12)


def _model_l(c: Canvas, ox: int, char: str, action: str) -> None:
    variant = FIGHTER_ACTIONS.index(action)
    attack = action.startswith(("normal", "command", "special", "spell"))
    airborne = action in ("jump", "air_dash")
    down = action == "down"
    lean = 3 if action in ("ground_dash", "air_dash") or attack else 0
    base = 47 if action == "crouch" else 43 if not airborne else 35
    cx = ox + 16 + lean
    if down:
        _model_l_down(c, ox, char)
        return
    # Larger fighter construction is authored independently from Model M.
    c.circle(cx, base-27, 6); _face(c,cx,base-27)
    c.poly([(cx-5,base-20),(cx+5,base-20),(cx+7,base-3),(cx-7,base-3)])
    if char == "reimu_hakurei":
        c.poly([(cx-4,base-31),(cx-13,base-37),(cx-11,base-25)]); c.poly([(cx+4,base-31),(cx+13,base-37),(cx+11,base-25)])
        c.rect(cx-13,base-19,6,12); c.rect(cx+8,base-19,6,12); c.line(cx+8,base-17,cx+14,base-34 if attack else base-23,BLACK,2)
        if action.startswith("spell"): c.circle(cx,base-18,13,hollow=True)
    elif char == "marisa_kirisame":
        c.poly([(cx-14,base-27),(cx+14,base-27),(cx+3,base-39),(cx-5,base-39)]); c.rect(cx-10,base-28,20,3)
        c.poly([(cx-4,base-17),(cx+4,base-17),(cx+9,base-2),(cx-9,base-2)]); c.line(cx-14,base-1,cx+14,base-30 if attack else base-16,BLACK,2)
        if action.startswith("spell"): _star(c,cx+12,base-35,6)
    elif char == "sakuya_izayoi":
        c.rect(cx-6,base-35,3,3,WHITE); c.rect(cx-1,base-37,3,3,WHITE); c.rect(cx+4,base-35,3,3,WHITE)
        c.poly([(cx-5,base-20),(cx+5,base-20),(cx+10,base-2),(cx-10,base-2)]); c.rect(cx-2,base-18,4,14,WHITE)
        for k in range(4): c.line(cx+5,base-18,cx+15,base-32+k*5)
    elif char == "remilia_scarlet":
        c.rect(cx-6,base-34,12,3); c.poly([(cx-5,base-19),(cx-15,base-31),(cx-12,base-5)]); c.poly([(cx+5,base-19),(cx+15,base-31),(cx+12,base-5)])
        c.line(cx+5,base-18,cx+15,base-38 if attack else base-8,BLACK,2)
    elif char == "youmu_konpaku":
        c.line(cx-8,base-4,cx+15,base-35 if attack else base-15,BLACK,2); c.line(cx-5,base-2,cx+14,base-18,BLACK,2)
        c.circle(cx+12,base-10,5); c.circle(cx+15,base-8,2,WHITE)
        if attack: c.line(ox+2,base-25,ox+30,base-25)
    elif char == "aya_shameimaru":
        c.rect(cx-4,base-39,8,5); c.poly([(cx-4,base-20),(cx-15,base-30),(cx-11,base-4)]); c.stroke(cx+5,base-23,9,7)
        if attack:
            for k in range(3): c.line(ox+1,base-30+k*6,ox+12,base-34+k*6)
    elif char == "sanae_kochiya":
        c.rect(cx-7,base-33,14,22); c.circle(cx-6,base-39,3,hollow=True); c.circle(cx+6,base-39,3,hollow=True)
        c.rect(cx-14,base-20,7,11); c.rect(cx+8,base-20,7,11); c.line(cx+8,base-17,cx+14,base-36 if attack else base-24,BLACK,2)
        if action.startswith("spell"): c.circle(cx,base-18,13,hollow=True); c.circle(cx,base-18,9,hollow=True)
    else:
        c.rect(cx-10,base-34,20,3); c.circle(cx,base-39,3); c.stroke(cx-15,base-20,8,8)
        c.line(cx+6,base-17,cx+15,base-39 if attack else base-8,BLACK,2)
        if action.startswith("spell"): c.line(ox+1,base-2,ox+30,base-10); c.rect(cx-4,base-9,8,7)
    if action in ("guard_high", "guard_low"): c.stroke(cx-10,base-32 if action.endswith("high") else base-17,20,14)
    # The complete contract uses distinct readable key poses even before in-betweens.
    if action.startswith("normal_"):
        n = int(action[-1]) - 1
        c.line(cx-5,base-17,cx+10+n,base-30+n*4,BLACK,1 if n < 2 else 2)
    elif action.startswith("command_normal_"):
        n = int(action[-1])
        c.line(ox+2,base-4 if n == 1 else base-31,ox+29,base-12 if n == 1 else base-5,BLACK,2)
    elif action.startswith("special_"):
        n = int(action[-1])
        c.circle(ox+5+(n*5)%23,base-28+(n%2)*10,2+n,hollow=True)
    elif action.startswith("spell_"):
        c.stroke(ox+1,2,30,44,BLACK,1 if action.endswith("1") else 2)
    elif action == "hit":
        c.line(cx-8,base-30,cx+8,base-12); c.line(cx+8,base-30,cx-8,base-12)
    elif action == "win":
        c.line(cx-6,base-20,cx-12,base-39,BLACK,2); c.line(cx+6,base-20,cx+12,base-39,BLACK,2)
    elif action == "focus_cancel":
        c.circle(cx,base-18,14,hollow=True)
    elif action == "spell_declaration":
        c.stroke(cx-10,base-31,20,24,BLACK,2)
    elif action == "throw":
        c.line(cx-5,base-18,ox+29,base-25,BLACK,2); c.line(cx+4,base-17,ox+28,base-13,BLACK,2)
        c.circle(ox+28,base-19,4,hollow=True)
    elif action == "jump":
        c.line(cx-6,base-4,cx-12,base+5,BLACK,2); c.line(cx+5,base-4,cx+12,base+2,BLACK,2)
    elif action == "air_dash":
        for trail in range(3): c.line(ox+1,base-24+trail*5,ox+8,base-24+trail*5)
    elif action == "ground_dash":
        c.line(ox+1,base-2,ox+13,base-2,BLACK,2); c.line(ox+2,base-8,ox+10,base-8)
    elif action == "crouch":
        c.line(cx-8,base-12,cx+8,base-12,BLACK,2)
    elif action == "walk_forward":
        c.line(cx-8,base-3,cx-12,base+2,BLACK,2)
    elif action == "walk_back":
        c.line(cx+7,base-3,cx+12,base+2,BLACK,2)
    if action == "surrender": c.line(cx-10,base-22,cx+10,base-30); c.line(cx-10,base-30,cx+10,base-22)
    foot_shift = (-2, 2)[variant % 2] if action in ("walk_forward", "walk_back", "ground_dash") else 0
    c.rect(cx-6+min(0,foot_shift),base-3,4,3); c.rect(cx+3+max(0,foot_shift),base-3,4,3)


def model_l_sheet(char: str) -> Canvas:
    c = Canvas(32 * len(FIGHTER_ACTIONS), 48)
    for i, action in enumerate(FIGHTER_ACTIONS): _model_l(c, i * 32, char, action)
    return c


def _portrait(c: Canvas, ox: int, char: str, expression: str) -> None:
    cx = ox + 40
    # Shoulders and head masses remain character-specific at portrait scale.
    c.poly([(ox+8,103),(ox+14,72),(cx-16,62),(cx+16,62),(ox+66,72),(ox+72,103)])
    c.circle(cx,42,23); c.rect(cx-16,31,32,34,WHITE)
    if char == "reimu_hakurei":
        c.poly([(cx-12,22),(ox+3,7),(ox+8,38)]); c.poly([(cx+12,22),(ox+77,7),(ox+72,38)]); c.rect(ox+5,75,15,24); c.rect(ox+60,75,15,24)
    elif char == "marisa_kirisame":
        c.poly([(ox+5,25),(ox+75,25),(cx+10,1),(cx-14,1)]); c.rect(ox+12,25,56,5); c.poly([(cx-14,65),(cx+14,65),(cx+23,103),(cx-23,103)],WHITE)
    elif char == "sakuya_izayoi":
        for x in (-15,-5,5,15): c.rect(cx+x-2,13+abs(x)//5,5,7,WHITE)
        c.rect(cx-6,66,12,32,WHITE); c.line(ox+62,76,ox+76,58); c.line(ox+62,76,ox+78,72)
    elif char == "remilia_scarlet":
        c.rect(cx-20,14,40,7); c.poly([(ox+14,75),(ox+1,51),(ox+8,101)]); c.poly([(ox+66,75),(ox+79,51),(ox+72,101)])
    elif char == "youmu_konpaku":
        c.line(ox+10,99,ox+70,54,BLACK,3); c.circle(ox+67,82,10); c.circle(ox+72,86,4,WHITE)
    elif char == "aya_shameimaru":
        c.rect(cx-9,3,18,14); c.poly([(ox+17,73),(ox+1,49),(ox+7,103)]); c.stroke(ox+59,69,17,14)
    elif char == "sanae_kochiya":
        c.rect(cx-24,27,48,66); c.rect(cx-16,31,32,34,WHITE); c.circle(cx-18,8,8,hollow=True); c.circle(cx+18,8,8,hollow=True); c.rect(ox+5,75,17,24); c.rect(ox+58,75,17,24)
    else:
        c.rect(cx-27,17,54,7); c.circle(cx,9,8); c.stroke(ox+6,74,18,18); c.line(ox+58,96,ox+76,55,BLACK,3)
    eye_y = 42
    if expression == "work_neutral":
        c.rect(cx-10,eye_y,4,2); c.rect(cx+6,eye_y,4,2); c.line(cx-4,56,cx+4,56)
        c.line(ox+58,78,ox+69,70)
    elif expression == "social_neutral":
        c.rect(cx-10,eye_y-1,4,2); c.rect(cx+6,eye_y-1,4,2); c.line(cx-5,55,cx,57); c.line(cx,57,cx+5,55)
    elif expression == "tired_private":
        c.line(cx-10,eye_y,cx-5,eye_y+1); c.line(cx+5,eye_y+1,cx+10,eye_y)
        c.line(cx-4,57,cx+4,58); c.line(ox+14,78,ox+25,85)
    elif expression == "startled":
        c.circle(cx-8,eye_y,2,hollow=True); c.circle(cx+8,eye_y,2,hollow=True); c.circle(cx,56,2,hollow=True)
    elif expression == "amused":
        c.line(cx-10,eye_y+1,cx-6,eye_y-1); c.line(cx+6,eye_y-1,cx+10,eye_y+1); c.line(cx-5,55,cx+5,57)
    elif expression == "irritated":
        c.rect(cx-10,eye_y,4,2); c.rect(cx+6,eye_y,4,2)
        c.line(cx-12,eye_y-5,cx-5,eye_y-2,BLACK,2); c.line(cx+5,eye_y-2,cx+12,eye_y-5,BLACK,2)
        c.line(cx-5,58,cx,56); c.line(cx,56,cx+5,58)
    elif expression == "focused":
        c.rect(cx-10,eye_y,4,2); c.rect(cx+6,eye_y,4,2)
        c.line(cx-12,eye_y-4,cx-6,eye_y-3); c.line(cx+6,eye_y-3,cx+12,eye_y-4)
        c.line(cx,50,cx,55); c.line(cx-3,57,cx+4,57)
    elif expression == "sincere_restrained":
        c.line(cx-10,eye_y,cx-6,eye_y+1); c.line(cx+6,eye_y+1,cx+10,eye_y)
        c.line(cx-3,56,cx,57); c.line(cx,57,cx+3,56); c.rect(ox+56,78,9,12,WHITE); c.line(ox+56,84,ox+65,78)
    else:  # route_vulnerable
        c.rect(cx-11,eye_y+1,3,2); c.rect(cx+5,eye_y,3,2)
        c.line(cx-3,58,cx+4,59); c.line(ox+16,82,ox+27,75); c.line(ox+53,75,ox+64,82)


def portrait_pack(char: str) -> Canvas:
    c = Canvas(80 * len(PORTRAIT_EXPRESSIONS), 104)
    for i, expression in enumerate(PORTRAIT_EXPRESSIONS): _portrait(c, i*80, char, expression)
    return c


def _star(c: Canvas, cx: int, cy: int, r: int) -> None:
    c.line(cx-r,cy,cx+r,cy); c.line(cx,cy-r,cx,cy+r); c.line(cx-r+2,cy-r+2,cx+r-2,cy+r-2); c.line(cx+r-2,cy-r+2,cx-r+2,cy+r-2)


def region_tiles(region: str) -> Canvas:
    c = Canvas(128,128)
    for index in range(64):
        ox, oy = (index%8)*16, (index//8)*16
        v, group = index%8, index//8
        if region == "hakurei_shrine":
            if group%4==0: c.rect(ox+3,oy+3+v%3,10,2); c.rect(ox+5,oy+5,2,10); c.rect(ox+9,oy+5,2,10)
            elif group%4==1: c.line(ox,oy+13,ox+15,oy+5+v%4,BLACK,2); c.line(ox+2,oy+10,ox+13,oy+10)
            elif group%4==2: c.line(ox+8,oy+1,ox+8,oy+15); c.line(ox+4,oy+5,ox+12,oy+5); c.line(ox+5,oy+6,ox+3,oy+10); c.line(ox+11,oy+6,ox+13,oy+10)
            else: c.circle(ox+8,oy+8,5,hollow=True); c.line(ox+3,oy+8,ox+13,oy+8); c.circle(ox+6,oy+7,1); c.circle(ox+10,oy+9,1,WHITE)
        elif region == "scarlet_devil_mansion":
            if group%4==0: c.stroke(ox+1,oy+1,14,14); c.line(ox+1,oy+6,ox+15,oy+6); c.line(ox+5,oy+1,ox+5,oy+6)
            elif group%4==1: c.circle(ox+8,oy+8,6,hollow=True); c.line(ox+8,oy+8,ox+8+v%4,oy+3); c.line(ox+8,oy+8,ox+12,oy+10)
            elif group%4==2: c.stroke(ox+4,oy+2,8,14); c.line(ox+8,oy+2,ox+8,oy+16); c.line(ox+4,oy+8,ox+12,oy+8)
            else: c.poly([(ox+2,oy+12),(ox+8,oy+3),(ox+14,oy+12),(ox+10,oy+9),(ox+8,oy+14),(ox+6,oy+9)])
        elif region == "youkai_mountain":
            if group%4==0: c.poly([(ox,oy+15),(ox+5+v%4,oy+2),(ox+10,oy+15)]); c.poly([(ox+7,oy+15),(ox+12,oy+6),(ox+16,oy+15)])
            elif group%4==1: [c.line(ox+1,oy+3+k*4,ox+14,oy+1+k*4) for k in range(4)]
            elif group%4==2: c.line(ox+8,oy,ox+8,oy+16,BLACK,2); c.poly([(ox+8,oy+2),(ox+2,oy+9),(ox+8,oy+8)]); c.poly([(ox+8,oy+6),(ox+14,oy+13),(ox+8,oy+12)])
            else: c.line(ox+2,oy+2,ox+2,oy+15); c.line(ox+14,oy+2,ox+14,oy+15); c.line(ox+2,oy+6+v%5,ox+14,oy+6+v%5)
        elif region == "eientei_bamboo_forest":
            if group%4==0:
                for x in (3,8,13): c.rect(ox+x,oy,2,16); c.line(ox+x,oy+4+v%4,ox+x+3,oy+2+v%4)
            elif group%4==1: c.circle(ox+8,oy+7,6,hollow=True); c.rect(ox,oy+12,16,4); c.checker(ox,oy+12,16,4)
            elif group%4==2: c.stroke(ox+1,oy+1,14,14); [c.line(ox+1,oy+k,ox+15,oy+k) for k in (5,10)]; [c.line(ox+k,oy+1,ox+k,oy+15) for k in (5,10)]
            else: c.circle(ox+5,oy+9,2); c.circle(ox+11,oy+6,2); c.line(ox+5,oy+7,ox+4,oy+2); c.line(ox+6,oy+7,ox+7,oy+2)
        else:
            if group%4==0: c.line(ox,oy+14,ox+15,oy+4+v%4,BLACK,2); c.circle(ox+5,oy+5,2,hollow=True); c.circle(ox+11,oy+3,1)
            elif group%4==1: c.circle(ox+7,oy+7,5); c.circle(ox+9,oy+6,4,WHITE); c.circle(ox+11,oy+10,2)
            elif group%4==2: [c.line(ox+1,oy+3+k*4,ox+15,oy+3+k*4) for k in range(4)]; c.line(ox+4+v%5,oy,ox+4+v%5,oy+16)
            else: c.line(ox+2,oy+14,ox+14,oy+2,BLACK,2); c.line(ox+5,oy+15,ox+15,oy+5); c.circle(ox+4,oy+5,2,hollow=True)
        # Rows 4–7 are explicit CALM/INCIDENT/ROUTE-SEASON/AFTER
        # overlays. A compact row/column code also guarantees every authored
        # tile has a stable unique identity without introducing grayscale.
        if group == 4: c.line(ox+2,oy+14,ox+5+v,oy+14)
        elif group == 5:
            for edge in range(v%4+1): c.set(ox+1+edge*3,oy+1)
        elif group == 6: c.stroke(ox+1,oy+1,4+v,4+(v%3)); c.set(ox+14,oy+14)
        elif group == 7: c.set(ox+2+v,oy+13); c.set(ox+13-v,oy+2)
        for bit in range(3):
            if v & (1 << bit): c.set(ox+2+bit*2,oy+15-group%2)
    return c


def bullet_library() -> Canvas:
    c = Canvas(96,32)
    for i, shape in enumerate(BULLETS):
        ox, oy = (i%6)*16, (i//6)*16; cx, cy = ox+8, oy+8
        if shape=="amulet": c.poly([(cx,oy+2),(ox+12,cy),(cx,oy+14),(ox+4,cy)]); c.rect(cx-1,oy+5,2,6,WHITE)
        elif shape=="needle": c.line(cx,oy+2,cx,oy+14,BLACK,2); c.line(cx-2,oy+4,cx+2,oy+4)
        elif shape=="orb": c.circle(cx,cy,5,hollow=True); c.circle(cx,cy,1)
        elif shape=="star": _star(c,cx,cy,5)
        elif shape=="knife": c.line(ox+3,oy+13,ox+12,oy+3,BLACK,2); c.line(ox+3,oy+13,ox+7,oy+12)
        elif shape=="butterfly": c.circle(cx-4,cy,3); c.circle(cx+4,cy,3); c.rect(cx,cy-3,1,7)
        elif shape=="leaf": c.poly([(ox+3,oy+11),(cx,oy+2),(ox+13,oy+5),(ox+11,oy+13)]); c.line(ox+4,oy+12,ox+12,oy+4,WHITE)
        elif shape=="arrow": c.line(ox+3,cy,ox+13,cy,BLACK,2); c.line(ox+13,cy,ox+9,cy-4); c.line(ox+13,cy,ox+9,cy+4)
        elif shape=="shard": c.poly([(cx,oy+1),(ox+12,oy+8),(ox+9,oy+14),(ox+4,oy+11)]); c.line(cx,oy+4,ox+8,oy+11,WHITE)
        elif shape=="plate": c.circle(cx,cy,6,hollow=True); c.line(ox+3,cy,ox+13,cy)
        elif shape=="spirit": c.circle(cx-2,cy-2,4); c.circle(cx,cy-3,3,WHITE); c.line(cx-4,cy+1,cx+4,cy+6,BLACK,2)
        else: c.stroke(ox+3,oy+3,10,10,BLACK,2); c.line(ox+4,oy+11,ox+11,oy+4)
    return c


def vfx_atlas(reduced: bool) -> Canvas:
    c = Canvas(64,128)
    for row, char in enumerate(CHARACTERS):
        for frame in range(4):
            ox, oy = frame*16, row*16; cx, cy = ox+8, oy+8
            r = 2+frame*2
            if char=="reimu_hakurei": c.circle(cx,cy,min(7,r),hollow=True)
            elif char=="marisa_kirisame": _star(c,cx,cy,min(7,r+1))
            elif char=="sakuya_izayoi": [c.line(ox+2+k*4,oy+14-frame,ox+8,oy+2+k%2) for k in range(frame+1)]
            elif char=="remilia_scarlet": c.poly([(ox+1,cy+frame-1),(cx,oy+2),(ox+7,cy),(cx,oy+14-frame)]); c.poly([(ox+15,cy-frame+1),(cx,oy+2),(ox+9,cy),(cx,oy+14-frame)])
            elif char=="youmu_konpaku": c.line(ox+1,oy+13-frame,ox+15,oy+3+frame,BLACK,1 if reduced else 2)
            elif char=="aya_shameimaru": [c.line(ox+1,oy+3+k*4,ox+15-frame,oy+1+k*4) for k in range(4)]
            elif char=="sanae_kochiya": c.circle(cx,cy,min(7,r),hollow=True); c.line(cx,oy+1,cx,oy+15); c.line(ox+1,cy,ox+15,cy)
            else: c.line(ox+1,oy+14-frame,ox+6,oy+8); c.line(ox+6,oy+8,ox+10+frame,oy+12-frame); c.line(ox+10,oy+12,ox+15,oy+2+frame)
            if not reduced and frame==2: c.circle(cx,cy,2,WHITE)
            if reduced:
                length=2+frame
                c.line(ox+1,oy+1,ox+1+length,oy+1); c.line(ox+1,oy+1,ox+1,oy+1+length)
                c.line(ox+14,oy+14,ox+14-length,oy+14); c.line(ox+14,oy+14,ox+14,oy+14-length)
    return c


def ui_export() -> Canvas:
    c=Canvas(256,128)
    # Frames, focus, buttons, tabs, toggles, meters and semantic marks.
    for i,t in enumerate((1,2,3)):
        c.stroke(4+i*80,4,72,28,BLACK,t)
    c.stroke(4,38,112,22); c.line(8,42,8,56,BLACK,2); c.line(8,42,16,42,BLACK,2)
    c.stroke(124,38,124,22,BLACK,2); c.line(128,56,244,56)
    for i in range(4): c.stroke(4+i*62,66,56,18,BLACK,2 if i==0 else 1)
    c.line(8,75,14,75,BLACK,2); c.line(14,75,11,72); c.line(14,75,11,78)
    for i in range(6):
        c.stroke(4+i*40,91,32,14); c.rect(7+i*40,94,8+i*3,8)
    c.circle(12,118,6,hollow=True); c.line(8,118,11,121,BLACK,2); c.line(11,121,17,114,BLACK,2)
    c.line(36,112,48,124,BLACK,2); c.line(48,112,36,124,BLACK,2)
    _star(c,72,118,6); c.circle(96,118,6,hollow=True); c.stroke(116,112,14,12,BLACK,2)
    return c


def _record(asset_id: str, path: str, kind: str, subject: str, canvas: Canvas, data: bytes) -> dict:
    return {
        "id": asset_id, "path": path, "kind": kind, "subject_id": subject,
        "dimensions": [canvas.width, canvas.height], "sha256": hashlib.sha256(data).hexdigest(),
        "bytes": len(data), "creator": "Gensokyo: Monochrome Heart project",
        "source_paths": [SCRIPT_PATH], "rights_basis": "project_original",
        "approval_status": "candidate_for_review",
        "approval_basis": "Deterministic original one-bit construction validated against the M16 production contracts.",
    }


def build() -> tuple[dict[str, bytes], dict]:
    files: dict[str, bytes] = {}; records=[]
    def add(asset_id: str, rel: str, kind: str, subject: str, canvas: Canvas) -> None:
        data=canvas.png(); path=f"assets/art/production/{rel}"; files[path]=data
        records.append(_record(asset_id,path,kind,subject,canvas,data))
    for char in CHARACTERS:
        add(f"asset.m16.{char}.model_m",f"characters/{char}/chr_{char}_m_core.png","model_m_sheet",char,model_m_sheet(char))
        add(f"asset.m16.{char}.model_l",f"characters/{char}/chr_{char}_l_keyposes.png","model_l_sheet",char,model_l_sheet(char))
        add(f"asset.m16.{char}.portraits",f"characters/{char}/portrait_{char}_nine_states.png","portrait_pack",char,portrait_pack(char))
    for region in REGIONS:
        add(f"asset.m16.{region}.tiles",f"regions/loc_{region}_tiles_64.png","region_tileset",region,region_tiles(region))
    add("asset.m16.bullets.core", "bullets/bul_core_shapes_12.png", "bullet_library", "core_bullets", bullet_library())
    add("asset.m16.vfx.standard", "vfx/vfx_launch_standard.png", "vfx_accessibility", "launch_fighters_standard", vfx_atlas(False))
    add("asset.m16.vfx.reduced_flash", "vfx/vfx_launch_reduced_flash.png", "vfx_accessibility", "launch_fighters_reduced_flash", vfx_atlas(True))
    add("asset.m16.ui.export", "ui/ui_one_bit_export_atlas.png", "ui_export", "ui_core", ui_export())
    manifest={
        "schema":"gmh-m16-visual-production-v1", "characters":list(CHARACTERS), "regions":list(REGIONS),
        "fighter_actions":list(FIGHTER_ACTIONS), "portrait_expressions":list(PORTRAIT_EXPRESSIONS),
        "bullet_shapes":list(BULLETS), "vfx_modes":["standard", "reduced_flash"],
        "region_layers":["far", "mid", "play", "front"],
        "region_states":["calm", "incident", "route", "season", "after"],
        "region_tile_rows":["terrain", "collision_edges", "architecture", "props", "calm", "incident", "route_season", "after"],
        "ui_components":{
            "frames":[[4,4,72,28],[84,4,72,28],[164,4,72,28]],
            "dialogue_frame":[4,38,112,22], "list_frame":[124,38,124,22],
            "tabs":[[4,66,56,18],[66,66,56,18],[128,66,56,18],[190,66,56,18]],
            "nine_patch_margin":[4,4,4,4], "native_scale_only":True,
        },
        "assets":records,
    }
    return files,manifest


def manifest_bytes(manifest: dict) -> bytes:
    return (json.dumps(manifest,indent=2,ensure_ascii=True)+"\n").encode()


def _unique_cells(canvas: Canvas, width: int, height: int) -> int:
    signatures=set()
    for oy in range(0,canvas.height,height):
        for ox in range(0,canvas.width,width):
            signatures.add(tuple(
                tuple(canvas.pixels[(oy+y)*canvas.width+ox:(oy+y)*canvas.width+ox+width])
                for y in range(height)
            ))
    return len(signatures)


def _cell_signature(canvas: Canvas, index: int, width: int, height: int) -> tuple:
    ox = index * width
    return tuple(
        tuple(canvas.pixels[y * canvas.width + ox:y * canvas.width + ox + width])
        for y in range(height)
    )


def _occupied_cell_bounds(canvas: Canvas, index: int, width: int, height: int) -> tuple[int, int]:
    ox = index * width
    occupied = [
        (x, y)
        for y in range(height)
        for x in range(width)
        if canvas.pixels[y * canvas.width + ox + x] != CLEAR
    ]
    if not occupied:
        return 0, 0
    xs, ys = zip(*occupied)
    return max(xs) - min(xs) + 1, max(ys) - min(ys) + 1


def quality_errors() -> list[str]:
    errors=[]
    down_signatures=set()
    for char in CHARACTERS:
        fighter_sheet=model_l_sheet(char)
        counts=(
            ("Model M",_unique_cells(model_m_sheet(char),24,32),10),
            ("Model L",_unique_cells(fighter_sheet,32,48),28),
            ("portrait",_unique_cells(portrait_pack(char),80,104),9),
        )
        for label,actual,minimum in counts:
            if actual < minimum: errors.append(f"{char} {label} unique cells {actual} < {minimum}")
        down_index=FIGHTER_ACTIONS.index("down")
        down_signatures.add(_cell_signature(fighter_sheet,down_index,32,48))
        down_width,down_height=_occupied_cell_bounds(fighter_sheet,down_index,32,48)
        if down_width < 24 or down_height < 14:
            errors.append(f"{char} down silhouette bounds {down_width}x{down_height} are not character-readable")
    if len(down_signatures) != len(CHARACTERS):
        errors.append("Model L down silhouettes do not preserve eight distinct character identities")
    for region in REGIONS:
        actual=_unique_cells(region_tiles(region),16,16)
        if actual < 40: errors.append(f"{region} unique tiles {actual} < 40")
    if _unique_cells(bullet_library(),16,16) != 12: errors.append("bullet families are not all visually unique")
    for mode,reduced in (("standard",False),("reduced_flash",True)):
        atlas=vfx_atlas(reduced)
        for row,char in enumerate(CHARACTERS):
            signatures=set()
            for frame in range(4):
                signatures.add(tuple(
                    tuple(atlas.pixels[(row*16+y)*atlas.width+frame*16:(row*16+y)*atlas.width+frame*16+16])
                    for y in range(16)
                ))
            if len(signatures) != 4: errors.append(f"{mode} VFX lacks four readable stages for {char}")
    return errors


def write() -> int:
    files,manifest=build()
    OUT.mkdir(parents=True,exist_ok=True)
    expected_paths={ROOT/path for path in files}
    for stale in OUT.rglob("*.png"):
        if stale not in expected_paths: stale.unlink()
    for path,data in files.items():
        target=ROOT/path; target.parent.mkdir(parents=True,exist_ok=True); target.write_bytes(data)
    (OUT/"production_manifest.json").write_bytes(manifest_bytes(manifest))
    print(f"M16 visual production written: assets={len(files)} manifest={OUT/'production_manifest.json'}")
    return 0


def check() -> int:
    files,manifest=build(); errors=[]
    expected={ROOT/path:data for path,data in files.items()}; expected[OUT/"production_manifest.json"]=manifest_bytes(manifest)
    actual={p for p in OUT.rglob("*.png") if p.is_file()} if OUT.exists() else set()
    if (OUT/"production_manifest.json").is_file(): actual.add(OUT/"production_manifest.json")
    for path,data in expected.items():
        if not path.is_file(): errors.append(f"missing: {path.relative_to(ROOT)}")
        elif path.read_bytes()!=data: errors.append(f"stale or nondeterministic: {path.relative_to(ROOT)}")
    for path in sorted(actual-set(expected)): errors.append(f"unexpected generated file: {path.relative_to(ROOT)}")
    errors.extend(quality_errors())
    for error in errors: print(f"ERROR {error}",file=sys.stderr)
    if errors: return 1
    print(f"M16 visual production check passed: assets={len(files)} characters={len(CHARACTERS)} regions={len(REGIONS)}")
    return 0


def main() -> int:
    parser=argparse.ArgumentParser(description=__doc__); mode=parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--write",action="store_true"); mode.add_argument("--check",action="store_true")
    args=parser.parse_args(); return write() if args.write else check()


if __name__ == "__main__": raise SystemExit(main())
