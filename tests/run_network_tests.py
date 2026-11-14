"""Exercise spectator hosting, large attacks and old-protocol rejection."""
import os
from pathlib import Path
import subprocess
import tempfile
import time

root = Path(__file__).resolve().parents[1]
engine = os.environ.get("GODOT_BIN", "godot")
processes = []
failed = False
with tempfile.TemporaryDirectory(prefix="downstack-net-") as scratch:
    try:
        for role in ("host", "player", "remote", "watch", "legacy"):
            path = Path(scratch) / f"{role}.log"
            output = path.open("w")
            process = subprocess.Popen(
                [engine, "--headless", "--path", str(root), "--script",
                 "tests/network_test.gd", "--", f"--role={role}", "--port=43971"],
                stdout=output, stderr=subprocess.STDOUT,
                env={**os.environ, "XDG_DATA_HOME": str(Path(scratch) / role)},
            )
            processes.append((role, process, output, path))
            time.sleep(0.3)
        for role, process, output, path in processes:
            result = process.wait(timeout=15)
            output.close()
            log = path.read_text()
            print(log.strip())
            if result != 0 or f"{role} NETWORK PASS" not in log or "SCRIPT ERROR" in log or " FAIL " in log:
                failed = True
    finally:
        for _, process, output, _ in processes:
            if process.poll() is None:
                process.terminate()
                process.wait(timeout=5)
            output.close()
raise SystemExit(1 if failed else 0)
