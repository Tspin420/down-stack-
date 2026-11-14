"""Install the pinned official Godot editor and Windows templates for release CI."""
import hashlib
import os
from pathlib import Path
import shutil
import urllib.request
import zipfile

VERSION = "4.6.3"
BASE = f"https://github.com/godotengine/godot-builds/releases/download/{VERSION}-stable/"
ASSETS = {
    f"Godot_v{VERSION}-stable_win64.exe.zip": "e39986a178d585ce7ac198fb8de6ea436366dc0cc00e594810c2e3e104c04b90",
    f"Godot_v{VERSION}-stable_export_templates.tpz": "3fbe2c0e2dec9d537ab9ec97bcf8da91dcf23357fc51f67092dd068d839290a8",
}


if __name__ == "__main__":
    if os.name != "nt":
        raise SystemExit("This installer is for the Windows GitHub Actions runner.")
    work = Path(os.environ["RUNNER_TEMP"]) / "downstack-godot"
    work.mkdir(parents=True, exist_ok=True)
    template_dir = Path(os.environ["APPDATA"]) / "Godot/export_templates" / f"{VERSION}.stable"
    template_dir.mkdir(parents=True, exist_ok=True)
    for name, expected in ASSETS.items():
        archive = work / name
        with urllib.request.urlopen(BASE + name, timeout=180) as source, archive.open("wb") as target:
            shutil.copyfileobj(source, target)
        with archive.open("rb") as source:
            actual = hashlib.file_digest(source, "sha256").hexdigest()
        if actual != expected:
            raise SystemExit(f"Official asset checksum mismatch: {name}")
        print(f"Verified {name}")
        with zipfile.ZipFile(archive) as zipped:
            for member in zipped.namelist():
                filename = Path(member).name
                if name.endswith(".tpz"):
                    if filename == "version.txt" or filename.startswith("windows_") and "x86_64" in filename:
                        (template_dir / filename).write_bytes(zipped.read(member))
                elif filename.endswith(".exe"):
                    (work / filename).write_bytes(zipped.read(member))
        archive.unlink()
    engine = work / f"Godot_v{VERSION}-stable_win64_console.exe"
    if not engine.is_file():
        raise SystemExit("Console editor executable is missing")
    with open(os.environ["GITHUB_ENV"], "a", encoding="utf-8") as output:
        output.write(f"GODOT_BIN={engine}\n")
