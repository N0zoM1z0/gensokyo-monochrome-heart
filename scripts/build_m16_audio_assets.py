#!/usr/bin/env python3
"""Build and verify deterministic, project-original M16 production audio.

The generator intentionally uses only integer oscillators, envelopes, and
deterministic noise. It reads no audio or MIDI input and encodes no melody
transcribed from an existing work.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Callable


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_ROOT = ROOT / "assets" / "audio" / "production"
MANIFEST_PATH = OUTPUT_ROOT / "production_manifest.json"
SOURCE_PATH = "res://scripts/build_m16_audio_assets.py"
SAMPLE_RATE = 22_050
CHANNELS = 1
PCM_LIMIT = 32_767
PHASE_MODULUS = 1 << 32
PHASE_MASK = PHASE_MODULUS - 1
GENERATOR_CREATOR = "Gensokyo: Monochrome Heart project"
APPROVAL_BASIS = (
    "Deterministically synthesized from project-authored integer oscillator, "
    "envelope, and noise code; contains no imported samples and no transcribed melody."
)


@dataclass(frozen=True)
class RegionSpec:
    slug: str
    cue_id: str
    bpm: int
    place_pitches_millihz: tuple[int, ...]
    person_pitches_millihz: tuple[int, ...]
    incident_seed: int


@dataclass(frozen=True)
class SfxSpec:
    asset_id: str
    filename: str
    family_id: str
    role: str
    voice_cap: int
    priority: int
    builder: Callable[[], list[int]]
    looped: bool = False


REGIONS = (
    RegionSpec(
        "hakurei_shrine",
        "mus_shrine_day",
        100,
        (98_000, 147_000, 196_000, 147_000),
        (294_000, 330_000, 392_000, 330_000, 294_000, 440_000, 392_000, 330_000),
        0x13579BDF,
    ),
    RegionSpec(
        "scarlet_devil_mansion",
        "mus_sdm_foyer",
        90,
        (82_000, 123_000, 164_000, 110_000),
        (246_000, 277_000, 369_000, 277_000, 330_000, 246_000, 415_000, 277_000),
        0x2468ACE1,
    ),
    RegionSpec(
        "youkai_mountain",
        "mus_mountain_base",
        120,
        (110_000, 165_000, 220_000, 147_000),
        (330_000, 440_000, 370_000, 494_000, 330_000, 555_000, 440_000, 370_000),
        0x10293847,
    ),
    RegionSpec(
        "eientei_bamboo",
        "mus_eirin_lab",
        105,
        (92_000, 138_000, 184_000, 123_000),
        (276_000, 310_000, 368_000, 414_000, 276_000, 349_000, 310_000, 460_000),
        0x55667789,
    ),
    RegionSpec(
        "hakugyokurou",
        "mus_hakugyokurou",
        84,
        (74_000, 111_000, 148_000, 99_000),
        (222_000, 264_000, 296_000, 352_000, 264_000, 396_000, 296_000, 222_000),
        0x6A09E667,
    ),
)


def clamp_pcm(value: int) -> int:
    return max(-PCM_LIMIT - 1, min(PCM_LIMIT, value))


def phase_increment(frequency_millihz: int) -> int:
    numerator = frequency_millihz * PHASE_MODULUS
    denominator = SAMPLE_RATE * 1_000
    return (numerator + denominator // 2) // denominator


def triangle_at(sample_index: int, frequency_millihz: int) -> int:
    phase = (sample_index * phase_increment(frequency_millihz)) & PHASE_MASK
    position = (phase >> 16) & 0xFFFF
    return clamp_pcm(32_767 - 2 * abs(position - 32_768))


def square_at(sample_index: int, frequency_millihz: int) -> int:
    phase = (sample_index * phase_increment(frequency_millihz)) & PHASE_MASK
    return PCM_LIMIT if phase < (PHASE_MODULUS // 2) else -PCM_LIMIT


def periodic_triangle(sample_index: int, frame_count: int, cycles: int) -> int:
    phase = ((sample_index % frame_count) * cycles * PHASE_MODULUS // frame_count) & PHASE_MASK
    position = (phase >> 16) & 0xFFFF
    return clamp_pcm(32_767 - 2 * abs(position - 32_768))


def deterministic_noise(sample_index: int, seed: int) -> int:
    value = (sample_index + 1) ^ seed
    value ^= (value << 13) & 0xFFFFFFFF
    value ^= value >> 17
    value ^= (value << 5) & 0xFFFFFFFF
    return ((value & 0xFFFF) - 32_768)


def envelope_q15(position: int, duration: int, attack: int, release: int) -> int:
    if position < 0 or position >= duration:
        return 0
    attack_gain = PCM_LIMIT if attack <= 0 else min(PCM_LIMIT, position * PCM_LIMIT // attack)
    remaining = duration - 1 - position
    release_gain = PCM_LIMIT if release <= 0 else min(PCM_LIMIT, remaining * PCM_LIMIT // release)
    return min(attack_gain, release_gain)


def add_tone(
    output: list[int],
    start: int,
    duration: int,
    frequency_millihz: int,
    amplitude: int,
    waveform: str,
    attack: int,
    release: int,
) -> None:
    end = min(len(output), start + duration)
    oscillator = triangle_at if waveform == "triangle" else square_at
    for sample_index in range(max(0, start), end):
        local = sample_index - start
        gain = envelope_q15(local, duration, attack, release)
        value = oscillator(sample_index, frequency_millihz)
        output[sample_index] += value * amplitude * gain // (PCM_LIMIT * PCM_LIMIT)


def add_noise_burst(
    output: list[int],
    start: int,
    duration: int,
    amplitude: int,
    seed: int,
    attack: int,
    release: int,
) -> None:
    end = min(len(output), start + duration)
    for sample_index in range(max(0, start), end):
        local = sample_index - start
        gain = envelope_q15(local, duration, attack, release)
        noise = deterministic_noise(sample_index, seed)
        output[sample_index] += noise * amplitude * gain // (PCM_LIMIT * PCM_LIMIT)


def finalized(samples: list[int]) -> list[int]:
    if samples:
        samples[0] = 0
        samples[-1] = 0
    return [clamp_pcm(value) for value in samples]


def music_frame_count(bpm: int, bars: int = 8) -> int:
    samples_per_beat = SAMPLE_RATE * 60 // bpm
    assert samples_per_beat * bpm == SAMPLE_RATE * 60
    return samples_per_beat * 4 * bars


def build_music_stem(region: RegionSpec, role: str) -> list[int]:
    samples_per_beat = SAMPLE_RATE * 60 // region.bpm
    frame_count = music_frame_count(region.bpm)
    output = [0] * frame_count
    total_beats = frame_count // samples_per_beat

    if role == "place":
        note_duration = samples_per_beat * 7 // 4
        for beat in range(0, total_beats, 2):
            pitch = region.place_pitches_millihz[(beat // 2) % len(region.place_pitches_millihz)]
            start = beat * samples_per_beat
            add_tone(
                output,
                start,
                note_duration,
                pitch,
                4_200,
                "triangle",
                samples_per_beat // 12,
                samples_per_beat // 4,
            )
            add_tone(
                output,
                start,
                note_duration,
                pitch * 3 // 2,
                1_500,
                "triangle",
                samples_per_beat // 10,
                samples_per_beat // 3,
            )
        for beat in range(total_beats):
            start = beat * samples_per_beat
            add_tone(
                output,
                start,
                samples_per_beat // 5,
                region.place_pitches_millihz[0] // 2,
                850,
                "square",
                samples_per_beat // 80,
                samples_per_beat // 8,
            )
    elif role == "person":
        note_duration = samples_per_beat * 3 // 5
        for beat in range(total_beats):
            if beat % 4 == 3:
                continue
            pitch = region.person_pitches_millihz[beat % len(region.person_pitches_millihz)]
            start = beat * samples_per_beat + samples_per_beat // 8
            add_tone(
                output,
                start,
                note_duration,
                pitch,
                2_700,
                "square",
                samples_per_beat // 24,
                samples_per_beat // 7,
            )
            add_tone(
                output,
                start,
                note_duration,
                pitch * 2,
                700,
                "triangle",
                samples_per_beat // 20,
                samples_per_beat // 6,
            )
    elif role == "incident":
        burst_duration = samples_per_beat // 5
        for beat in range(total_beats):
            offbeat = beat * samples_per_beat + samples_per_beat * (3 if beat % 4 == 2 else 1) // 4
            add_noise_burst(
                output,
                offbeat,
                burst_duration,
                2_000 if beat % 4 else 3_200,
                region.incident_seed,
                samples_per_beat // 100,
                samples_per_beat // 8,
            )
            if beat % 4 in (1, 3):
                add_tone(
                    output,
                    beat * samples_per_beat,
                    samples_per_beat // 3,
                    region.place_pitches_millihz[(beat + 1) % 4] * 5 // 4,
                    1_500,
                    "square",
                    samples_per_beat // 60,
                    samples_per_beat // 6,
                )
    else:
        raise ValueError(f"unknown stem role: {role}")

    return finalized(output)


def blank_seconds(milliseconds: int) -> list[int]:
    return [0] * (SAMPLE_RATE * milliseconds // 1_000)


def build_ui_focus() -> list[int]:
    output = blank_seconds(55)
    add_tone(output, 0, len(output), 740_000, 6_500, "triangle", 30, len(output) // 2)
    return finalized(output)


def build_ui_confirm() -> list[int]:
    output = blank_seconds(110)
    half = len(output) // 2
    add_tone(output, 0, half, 520_000, 5_800, "triangle", 40, half // 3)
    add_tone(output, half, len(output) - half, 780_000, 6_800, "square", 40, half // 2)
    return finalized(output)


def build_ui_cancel() -> list[int]:
    output = blank_seconds(100)
    phase = 0
    start_increment = phase_increment(520_000)
    end_increment = phase_increment(230_000)
    for index in range(len(output)):
        increment = start_increment + (end_increment - start_increment) * index // len(output)
        phase = (phase + increment) & PHASE_MASK
        value = PCM_LIMIT if phase < PHASE_MODULUS // 2 else -PCM_LIMIT
        gain = envelope_q15(index, len(output), 50, len(output) // 2)
        output[index] = value * 5_000 * gain // (PCM_LIMIT * PCM_LIMIT)
    return finalized(output)


def build_warning() -> list[int]:
    output = blank_seconds(420)
    unit = len(output) // 5
    for pulse in (0, 2, 4):
        add_tone(output, pulse * unit, unit, 880_000, 9_500, "square", 60, unit // 3)
        add_tone(output, pulse * unit, unit, 440_000, 3_000, "triangle", 60, unit // 2)
    return finalized(output)


def build_player_damage() -> list[int]:
    output = blank_seconds(190)
    add_noise_burst(output, 0, len(output), 10_000, 0xDEADBEEF, 20, len(output) * 3 // 4)
    add_tone(output, 0, len(output), 130_000, 8_000, "square", 20, len(output) * 3 // 4)
    return finalized(output)


def build_graze() -> list[int]:
    output = blank_seconds(48)
    add_tone(output, 0, len(output), 1_180_000, 5_500, "triangle", 15, len(output) * 3 // 4)
    add_noise_burst(output, 0, len(output), 2_200, 0xA5A5A5A5, 10, len(output) * 2 // 3)
    return finalized(output)


def build_bullet_group_loop() -> list[int]:
    output = blank_seconds(500)
    frame_count = len(output)
    for index in range(frame_count):
        carrier = periodic_triangle(index, frame_count, 36)
        motion = periodic_triangle(index, frame_count, 4)
        gate = 2_200 + (motion + PCM_LIMIT) * 1_100 // (PCM_LIMIT * 2)
        output[index] = carrier * gate // PCM_LIMIT
    return finalized(output)


def build_bullet_transient() -> list[int]:
    output = blank_seconds(36)
    add_noise_burst(output, 0, len(output), 4_200, 0xB16B00B5, 5, len(output) * 4 // 5)
    add_tone(output, 0, len(output), 920_000, 2_800, "square", 5, len(output) * 3 // 4)
    return finalized(output)


def build_impact() -> list[int]:
    output = blank_seconds(135)
    add_noise_burst(output, 0, len(output), 9_000, 0x1A2B3C4D, 10, len(output) * 4 // 5)
    add_tone(output, 0, len(output), 105_000, 8_500, "triangle", 10, len(output) * 4 // 5)
    return finalized(output)


def build_ambience_loop() -> list[int]:
    output = blank_seconds(2_000)
    frame_count = len(output)
    for index in range(frame_count):
        slow = periodic_triangle(index, frame_count, 3)
        slower = periodic_triangle(index, frame_count, 1)
        output[index] = slow * 950 // PCM_LIMIT + slower * 600 // PCM_LIMIT
    return finalized(output)


def build_save_begin() -> list[int]:
    output = blank_seconds(170)
    add_noise_burst(output, 0, len(output), 2_800, 0xC001D00D, 10, len(output) // 3)
    add_tone(output, len(output) // 3, len(output) * 2 // 3, 360_000, 3_800, "triangle", 30, len(output) // 3)
    return finalized(output)


def build_save_end() -> list[int]:
    output = blank_seconds(190)
    half = len(output) // 2
    add_tone(output, 0, half, 440_000, 4_000, "triangle", 30, half // 2)
    add_tone(output, half, len(output) - half, 660_000, 5_400, "triangle", 30, half // 2)
    return finalized(output)


SFX_SPECS = (
    SfxSpec("sfx.ui.focus", "ui_focus.wav", "ui_navigation", "ui", 3, 40, build_ui_focus),
    SfxSpec("sfx.ui.confirm", "ui_confirm.wav", "ui_navigation", "ui", 3, 50, build_ui_confirm),
    SfxSpec("sfx.ui.cancel", "ui_cancel.wav", "ui_navigation", "ui", 3, 45, build_ui_cancel),
    SfxSpec("sfx.warning.threat", "warning_threat.wav", "warning", "dialogue_warning", 2, 100, build_warning),
    SfxSpec("sfx.player.damage", "player_damage.wav", "player_critical", "player_critical", 3, 90, build_player_damage),
    SfxSpec("sfx.danmaku.graze", "danmaku_graze.wav", "graze", "gameplay", 4, 65, build_graze),
    SfxSpec("sfx.bullet.group_loop", "bullet_group_loop.wav", "bullet_group", "gameplay", 1, 25, build_bullet_group_loop, True),
    SfxSpec("sfx.bullet.transient", "bullet_transient.wav", "bullet_transient", "gameplay", 4, 35, build_bullet_transient),
    SfxSpec("sfx.combat.impact", "combat_impact.wav", "impact", "combat_high", 4, 75, build_impact),
    SfxSpec("sfx.ambience.region_bed", "ambience_region_bed.wav", "ambience", "ambience", 2, 10, build_ambience_loop, True),
    SfxSpec("sfx.save.begin", "save_begin.wav", "save", "ui", 2, 55, build_save_begin),
    SfxSpec("sfx.save.end", "save_end.wav", "save", "ui", 2, 60, build_save_end),
)


def chunk(chunk_id: bytes, payload: bytes) -> bytes:
    padding = b"\x00" if len(payload) % 2 else b""
    return chunk_id + struct.pack("<I", len(payload)) + payload + padding


def wav_bytes(samples: list[int], looped: bool) -> bytes:
    pcm = struct.pack(f"<{len(samples)}h", *samples)
    fmt = struct.pack(
        "<HHIIHH",
        1,
        CHANNELS,
        SAMPLE_RATE,
        SAMPLE_RATE * CHANNELS * 2,
        CHANNELS * 2,
        16,
    )
    chunks = [chunk(b"fmt ", fmt), chunk(b"data", pcm)]
    if looped:
        sample_period_ns = 1_000_000_000 // SAMPLE_RATE
        sampler_header = struct.pack(
            "<9I",
            0,
            0,
            sample_period_ns,
            60,
            0,
            0,
            0,
            1,
            0,
        )
        loop = struct.pack("<6I", 0, 0, 0, len(samples) - 1, 0, 0)
        chunks.append(chunk(b"smpl", sampler_header + loop))
    wave_payload = b"WAVE" + b"".join(chunks)
    return b"RIFF" + struct.pack("<I", len(wave_payload)) + wave_payload


def common_record(asset_id: str, path: str, kind: str, role: str, payload: bytes) -> dict[str, object]:
    return {
        "id": asset_id,
        "path": f"res://{path}",
        "kind": kind,
        "role": role,
        "sample_rate": SAMPLE_RATE,
        "channels": CHANNELS,
        "sha256": hashlib.sha256(payload).hexdigest(),
        "bytes": len(payload),
        "creator": GENERATOR_CREATOR,
        "rights_basis": "project_original",
        "approval_status": "candidate_for_review",
        "approval_basis": APPROVAL_BASIS,
        "source_paths": [SOURCE_PATH],
    }


def build_outputs() -> tuple[dict[str, bytes], dict[str, object]]:
    outputs: dict[str, bytes] = {}
    assets: list[dict[str, object]] = []

    for region in REGIONS:
        for role in ("place", "person", "incident"):
            samples = build_music_stem(region, role)
            relative_path = f"assets/audio/production/music/{region.slug}_{role}.wav"
            payload = wav_bytes(samples, looped=True)
            outputs[relative_path] = payload
            record = common_record(
                f"audio.music.{region.slug}.{role}",
                relative_path,
                "music_stem",
                role,
                payload,
            )
            record.update(
                {
                    "cue_id": region.cue_id,
                    "bpm": region.bpm,
                    "meter": "4/4",
                    "loop_start_sample": 0,
                    "loop_end_sample": len(samples),
                }
            )
            assets.append(record)

    for spec in SFX_SPECS:
        samples = spec.builder()
        relative_path = f"assets/audio/production/sfx/{spec.filename}"
        payload = wav_bytes(samples, looped=spec.looped)
        outputs[relative_path] = payload
        record = common_record(spec.asset_id, relative_path, "sfx", spec.role, payload)
        record.update(
            {
                "family_id": spec.family_id,
                "voice_cap": spec.voice_cap,
                "priority": spec.priority,
            }
        )
        assets.append(record)

    assets.sort(key=lambda item: str(item["id"]))
    manifest = {"schema": "gmh-m16-audio-production-v1", "assets": assets}
    return outputs, manifest


def manifest_bytes(manifest: dict[str, object]) -> bytes:
    return (json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + "\n").encode("utf-8")


def write_outputs(outputs: dict[str, bytes], manifest: dict[str, object]) -> None:
    expected_paths = {ROOT / relative for relative in outputs}
    expected_paths.add(MANIFEST_PATH)
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    for existing in sorted(OUTPUT_ROOT.rglob("*")):
        if existing.is_file() and existing.suffix not in {".import", ".uid"} and existing not in expected_paths:
            existing.unlink()
    for relative_path, payload in sorted(outputs.items()):
        target = ROOT / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(payload)
    MANIFEST_PATH.write_bytes(manifest_bytes(manifest))


def check_outputs(outputs: dict[str, bytes], manifest: dict[str, object]) -> list[str]:
    failures: list[str] = []
    expected: dict[Path, bytes] = {ROOT / relative: payload for relative, payload in outputs.items()}
    expected[MANIFEST_PATH] = manifest_bytes(manifest)
    for path, payload in sorted(expected.items(), key=lambda item: str(item[0])):
        if not path.is_file():
            failures.append(f"missing generated file: {path.relative_to(ROOT)}")
        elif path.read_bytes() != payload:
            failures.append(f"generated file differs: {path.relative_to(ROOT)}")
    if OUTPUT_ROOT.exists():
        for existing in sorted(OUTPUT_ROOT.rglob("*")):
            if existing.is_file() and existing.suffix not in {".import", ".uid"} and existing not in expected:
                failures.append(f"unexpected generated file: {existing.relative_to(ROOT)}")
    return failures


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--write", action="store_true", help="write deterministic WAV files and manifest")
    mode.add_argument("--check", action="store_true", help="verify checked-in outputs byte-for-byte")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    outputs, manifest = build_outputs()
    if args.write:
        write_outputs(outputs, manifest)
        print(f"M16 audio assets written: {len(outputs)} WAV files, {len(manifest['assets'])} manifest records")
        return 0
    failures = check_outputs(outputs, manifest)
    if failures:
        for failure in failures:
            print(f"ERROR: {failure}", file=sys.stderr)
        return 1
    print(f"M16 audio assets verified: {len(outputs)} WAV files, deterministic manifest")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
