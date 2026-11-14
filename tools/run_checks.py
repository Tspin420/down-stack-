"""Run every regression suite with isolated preferences on Windows or Linux."""
import os
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
ENGINE = os.environ.get("GODOT_BIN", "godot")
SUITES = ("core", "gravity", "garbage", "update", "input", "settings",
          "controller_drop", "input_audit", "buffer", "desktop", "visual", "menu")


def run(command, env=None):
    result = subprocess.run(command, cwd=ROOT, env=env, capture_output=True,
                            text=True, encoding="utf-8", errors="replace", timeout=90)
    print(result.stdout, end="")
    print(result.stderr, end="")
    if result.returncode or re.search(r"SCRIPT ERROR|ERROR:|FAIL:", result.stdout + result.stderr):
        raise SystemExit(result.returncode or 1)


if __name__ == "__main__":
    run([ENGINE, "--headless", "--path", str(ROOT), "--editor", "--import", "--quit"])
    for suite in SUITES:
        with tempfile.TemporaryDirectory(prefix="downstack-test-") as profile:
            run([ENGINE, "--headless", "--path", str(ROOT), "--script",
                 f"tests/{suite}_test.gd"],
                {**os.environ, "XDG_DATA_HOME": profile, "APPDATA": profile})
    import sys
    run([sys.executable, "tests/run_network_tests.py"])
