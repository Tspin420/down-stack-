# Repository and releases

Downstack's source lives at [Tspin420/down-stack-](https://github.com/Tspin420/down-stack-).
The repository root contains `project.godot`, `scripts`, `assets`, `tests` and
the documentation. Playable ZIPs belong in
[Releases](https://github.com/Tspin420/down-stack-/releases), not in Git history.

## Automated Windows release

`.github/workflows/release.yml` runs on `main` when `project.godot` or the release
workflow changes. It can also be run manually from the Actions page on `main`.
It uses a Windows runner to:

1. Read the project version and stop without changing an existing release.
2. Download official Godot 4.6.3 Standard and matching export templates,
   verifying their pinned SHA-256 digests before use.
3. Run all twelve regression suites with isolated preferences, then the
   five-process multiplayer test, including old-protocol rejection.
4. Export Windows x64, inspect its executable type, generate the shortcut helper
   and ICO, and smoke-test the actual exported executable headlessly.
5. Package the game, documentation, notices and source-commit metadata.
6. Create the version tag at the tested commit and publish the ZIP and SHA-256
   file using `RELEASE_NOTES.md` as the release description.

The workflow uses GitHub's repository-scoped token with `contents: write` only
in the release job. It does not need a personal access token or signing secret.
It runs only from `main`; a pull request cannot publish a release.
If a check fails, the job stops before publication. Existing versioned release
assets are preserved; make a new version for changed game binaries.

For the next release, update `config/version` in `project.godot`, the matching
four-part Windows file/product versions in `export_presets.cfg`, `README.md`,
`CHANGELOG.md`, `RELEASE_NOTES.md` and `VALIDATION.md`. Merge the reviewed changes
to `main`, then check the Windows release workflow until it finishes.

## Local verification and packaging

Install Python 3.11+, Godot 4.6.3 Standard and its matching official Windows
export templates. Set `GODOT_BIN` to the engine executable if it is not named
`godot` on PATH. On Windows, use the editor's `_console.exe` for captured logs.
From the repository root:

```text
python tools/run_checks.py
python tools/build_release.py --output ../release
```

The package is `Downstack_Windows_0.9.0.zip` plus `.zip.sha256`. Packaging refuses
to replace an existing ZIP. `BUILD_INFO.json` records the source commit and
whether the working tree was dirty. Publish from a clean, committed checkout.
On Linux the export's PCK is smoke-tested in Linux Godot; only the Windows
workflow smoke-tests the Windows executable. Neither is a frame-pacing test.

Keep original assets, `.import` settings and `.uid` files in Git. Ignore rules
exclude generated caches, executables and local preferences. The MIT project
license and Godot/third-party notices are included in every package.

References: [Godot Windows export](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_windows.html),
[GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases).
