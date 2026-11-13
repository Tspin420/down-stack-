"""Exercise spectator hosting and mixed local/remote players on loopback."""
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
        for role in ("host", "player", "remote", "watch"):
            path = Path(scratch) / f"{role}.log"
            output = path.open("w")
            process = subprocess.Popen(
                [engine, "--headless", "--path", str(root), "--script",
                 "tests/network_test.gd", "--", f"--role={role}", "--port=43971"],
                stdout=output, stderr=subprocess.STDOUT,
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
