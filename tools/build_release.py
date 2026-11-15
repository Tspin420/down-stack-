"""Export and package a versioned Windows x64 release with a SHA-256 checksum.

Requires Python 3.11+, Godot 4.6.3 Standard and matching Windows export templates.
Set GODOT_BIN if Godot is not on PATH. The game itself has no Python dependency.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import tempfile
import zipfile

from make_shortcut_helper import build as build_shortcut
from check_branding import main as check_branding

ROOT = Path(__file__).resolve().parents[1]
ENGINE = os.environ.get("GODOT_BIN", "godot")


def command(args, **kwargs):
    result = subprocess.run(args, capture_output=True, text=True, encoding="utf-8",
                            errors="replace", timeout=180, **kwargs)
    print(result.stdout, end="")
    print(result.stderr, end="")
    if result.returncode or re.search(r"SCRIPT ERROR|ERROR:|FAIL:", result.stdout + result.stderr):
        raise SystemExit(result.returncode or 1)
    return result.stdout.strip()


def build(destination):
    if check_branding() != 0:
        raise SystemExit("Resolve wording audit before packaging.")
    project = (ROOT / "project.godot").read_text()
    version = re.search(r'^config/version="([0-9]+\.[0-9]+\.[0-9]+)"$',
                        project, re.M).group(1)
    def setting(name):
        return int(re.search(r"^" + re.escape(name) + r"=(\d+)$", project, re.M).group(1))
    protocol = int(re.search(r"^const PROTOCOL = (\d+)$",
                            (ROOT / "scripts/session.gd").read_text(), re.M).group(1))
    engine_version = command([ENGINE, "--version"])
    if not engine_version.startswith("4.6.3.stable"):
        raise SystemExit("Use Godot 4.6.3 Standard and matching export templates.")
    preset = (ROOT / "export_presets.cfg").read_text()
    for field in ("file_version", "product_version"):
        if f'application/{field}="{version}.0"' not in preset:
            raise SystemExit("Windows version metadata differs from project.godot")
    source_commit = command(["git", "rev-parse", "HEAD"], cwd=ROOT)
    source_dirty = bool(command(["git", "status", "--porcelain"], cwd=ROOT))
    destination.mkdir(parents=True, exist_ok=True)
    archive = destination / f"Downstack_Windows_{version}.zip"
    if archive.exists():
        raise SystemExit(f"Refusing to replace an existing package: {archive}")
    with tempfile.TemporaryDirectory(prefix="downstack-build-") as temp:
        stage = Path(temp) / f"Downstack_{version}"
        stage.mkdir()
        command([ENGINE, "--headless", "--path", str(ROOT), "--editor", "--import", "--quit"])
        exe = stage / "Downstack.exe"
        command([ENGINE, "--headless", "--path", str(ROOT), "--export-release",
                 "Windows Desktop", str(exe)])
        # Verify this is the expected 64-bit Windows executable and external pack.
        data = exe.read_bytes()
        pe_offset = struct.unpack_from("<I", data, 0x3C)[0]
        if data[:2] != b"MZ" or data[pe_offset:pe_offset + 4] != b"PE\0\0":
            raise SystemExit("Export did not produce a Windows executable")
        if struct.unpack_from("<H", data, pe_offset + 4)[0] != 0x8664:
            raise SystemExit("Export is not Windows x86_64")
        pack = stage / "Downstack.pck"
        if not pack.is_file() or pack.stat().st_size < 1024:
            raise SystemExit("Exported project data is missing")
        command([ENGINE, "--headless", "--path", str(ROOT), "--script",
                 "tools/export_icon.gd", "--", str(stage / "Downstack.ico")])
        build_shortcut(stage / "Create Desktop Shortcut.cmd")
        for name in ("README.md", "RELEASE_NOTES.md", "CHANGELOG.md", "VALIDATION.md",
                     "RULES_REFERENCE.md", "SOFT_DROP_REFERENCE.md", "INPUT_AUDIT.md",
                     "BUFFER_NOTES.md", "LICENSE.txt"):
            shutil.copy2(ROOT / name, stage / name)
        shutil.copytree(ROOT / "licenses", stage / "licenses")
        # Test the release binary on Windows; on other hosts load its actual PCK.
        with tempfile.TemporaryDirectory(prefix="downstack-smoke-") as profile:
            smoke = [str(exe)] if os.name == "nt" else [ENGINE, "--main-pack", str(pack)]
            smoke_log = Path(profile) / "smoke.log"
            command(smoke + ["--headless", "--quit-after", "120", "--log-file", str(smoke_log)], cwd=stage,
                    env={**os.environ, "XDG_DATA_HOME": profile, "APPDATA": profile})
            log = smoke_log.read_text(encoding="utf-8", errors="replace")
            if "Godot Engine" not in log or re.search(r"SCRIPT ERROR|ERROR:", log):
                raise SystemExit(f"Exported-game startup failed: {log}")
        (stage / "BUILD_INFO.json").write_text(json.dumps({
            "version": version, "source_commit": source_commit,
            "source_dirty": source_dirty, "godot": engine_version,
            "built_at_utc": datetime.now(timezone.utc).isoformat(),
            "platform": "Windows x86_64", "physics_hz": setting("common/physics_ticks_per_second"),
            "render_fps_cap": setting("run/max_fps"),
            "vsync_mode": setting("window/vsync/vsync_mode"), "network_protocol": protocol,
            "smoke_test": "Windows release executable" if os.name == "nt" else "PCK in Linux Godot",
        }, indent=2) + "\n", encoding="utf-8")
        with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as zipped:
            for path in sorted(stage.rglob("*")):
                if path.is_file():
                    zipped.write(path, path.relative_to(stage.parent))
    with archive.open("rb") as source:
        digest = hashlib.file_digest(source, "sha256").hexdigest()
    checksum = archive.with_suffix(".zip.sha256")
    checksum.write_text(f"{digest}  {archive.name}\n", encoding="ascii")
    with zipfile.ZipFile(archive) as zipped:
        if zipped.testzip() is not None:
            raise SystemExit("ZIP integrity check failed")
    print(f"PACKAGE PASS: {archive} ({archive.stat().st_size} bytes)")
    print(f"SHA256: {digest}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT.parent / "release")
    build(parser.parse_args().output.resolve())
