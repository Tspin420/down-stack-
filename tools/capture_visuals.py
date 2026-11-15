"""Render reproducible before/after fixtures using the actual Godot board renderers.

Needs a desktop display and Godot 4.6.3. No third-party Python packages.
The temporary baseline script is removed even if capture fails.
"""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--baseline", default="922ecc260d1155661c07052d52fc30c64002007f")
parser.add_argument("--baseline-file", type=Path, help="Compare an earlier local board_view.gd instead of a commit")
parser.add_argument("--output", type=Path, default=root / "build" / "visual-review")
args = parser.parse_args()
source = args.baseline_file.read_bytes() if args.baseline_file else subprocess.check_output(
    ["git", "show", f"{args.baseline}:scripts/board_view.gd"], cwd=root
)
engine = os.environ.get("GODOT_BIN", "godot")
output = args.output.resolve()
output.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix="visual-baseline-", dir=root / "tools") as temp:
    script = Path(temp) / "board_view.gd"
    script.write_bytes(source)
    resource = "res://" + script.relative_to(root).as_posix()
    run = subprocess.run(
        [engine, "--path", str(root), "--rendering-method", "gl_compatibility",
         "--audio-driver", "Dummy", "--script", "res://tools/visual_capture.gd",
         "--", f"--output={output}", f"--baseline={resource}",
         "--baseline-label=previous visual prototype" if args.baseline_file else "--baseline-label=repository baseline"],
        cwd=root, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=60,
    )
    (output / "capture.log").write_text(run.stdout)
    print(run.stdout)
    if run.returncode or "SCRIPT ERROR" in run.stdout or "VISUAL CAPTURE PASS" not in run.stdout:
        raise SystemExit(1)
