#!/usr/bin/env python3
"""Audit all tracked filenames and text, without document or license exemptions."""
from __future__ import annotations
import re
import subprocess
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
# Escaped search terms avoid putting restricted product names in this file.
PATTERN = re.compile(r"\x74\x65\x74\x72\x69\x73|\x70\x75\x79\x6f|\b\x70\x70\x74\d?\b|\x74\x65\x74\x72\x69\x6d\x69\x6e\x6f", re.IGNORECASE)
BINARY_TERMS = ("\x74\x65\x74\x72\x69\x73", "\x70\x75\x79\x6f", "\x74\x65\x74\x72\x69\x6d\x69\x6e\x6f")


def contains(text: str) -> bool:
    return PATTERN.search(unicodedata.normalize("NFKC", text)) is not None


def self_test() -> None:
    samples = ("\x74\x65\x74\x72\x69\x73", "\x70\x75\x79\x6f", "\x70\x70\x74", "\x70\x70\x74\x31", "\x74\x65\x74\x72\x69\x6d\x69\x6e\x6f")
    for sample in samples:
        for value in (sample, sample.upper(), "[" + sample + "]"):
            assert contains(value), "Missed restricted wording"
    for value in ("Downstack", "quad", "tetromino", "pptx", "T-spin", "Godot"):
        assert not contains(value), "False-positive wording match"
    assert contains("https://example.invalid/" + samples[0] + "/rules")
    assert contains("\uff34\uff25\uff34\uff32\uff29\uff33")


def inspect_file(path: Path) -> tuple[str, bool]:
    raw = path.read_bytes()
    if raw.startswith((b"\xff\xfe", b"\xfe\xff")):
        try:
            return "text", contains(raw.decode("utf-16"))
        except UnicodeError:
            pass
    try:
        text = raw.decode("utf-8-sig")
        if "\0" not in text:
            return "text", contains(text)
    except UnicodeError:
        pass
    lower = raw.lower()
    found = any(term.encode(enc) in lower for term in BINARY_TERMS
                for enc in ("utf-8", "utf-16-le", "utf-16-be"))
    return "binary", found


def main() -> int:
    self_test()
    names = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT).decode("utf-8").split("\0")
    counts = {"text": 0, "binary": 0}
    problems = []
    for name in filter(None, names):
        if contains(name):
            problems.append("restricted filename")
        try:
            kind, found = inspect_file(ROOT / name)
        except OSError as exc:
            problems.append(f"{name}: unreadable ({exc})")
            continue
        counts[kind] += 1
        if found:
            problems.append(f"{name}: restricted wording")
    for problem in problems:
        print(problem)
    print(f"Checked {counts['text']} text files and embedded strings in {counts['binary']} binary files; no exemptions.")
    print("This is a current-checkout wording test, not a pixels/audio or repository-history audit.")
    print(f"FAIL: {len(problems)} findings." if problems else "PASS: no restricted wording or filenames.")
    return int(bool(problems))


if __name__ == "__main__":
    raise SystemExit(main())
