"""Build the Windows double-click helper from the in-game PowerShell source."""
from pathlib import Path
import sys


def build(destination: Path):
    source = Path(__file__).resolve().parents[1] / "windows/create_shortcut.ps1"
    script = " ".join(line.strip() for line in source.read_text().splitlines()
                      if line.strip() and not line.lstrip().startswith("#"))
    # Literal quotes/percent signs would need CMD escaping. Paths are carried
    # in an environment value, never pasted into the command or script source.
    assert '"' not in script and '%' not in script and '\n' not in script
    command = '\r\n'.join([
        '@echo off', 'setlocal DisableDelayedExpansion',
        'set "DOWNSTACK_SHORTCUT_TARGET=%~dp0Downstack.exe"',
        'if not exist "%SystemRoot%\\System32\\WindowsPowerShell\\v1.0\\powershell.exe" goto missing',
        '"%SystemRoot%\\System32\\WindowsPowerShell\\v1.0\\powershell.exe" -NoLogo -NoProfile -NonInteractive -Command "' + script + '"',
        'if errorlevel 1 goto failed',
        'echo Keep the extracted game folder in place after making the shortcut.',
        'pause', 'exit /b 0', ':missing',
        'echo Windows PowerShell is unavailable.', ':failed',
        'echo Shortcut creation failed. Extract the entire ZIP first.',
        'echo You can also right-click Downstack.exe and use Send to Desktop.',
        'pause', 'exit /b 1', ''])
    assert max(map(len, command.splitlines())) < 8191
    destination.write_bytes(command.encode("ascii"))


if __name__ == "__main__":
    build(Path(sys.argv[1]))
