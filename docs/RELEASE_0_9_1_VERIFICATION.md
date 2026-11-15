# Verified release — Downstack 0.9.1

Release source commit: `01d1caa70721a4e78ec899ce25cb799afc909c16`.
Published Windows archive: `Downstack_Windows_0.9.1.zip` (38,469,852 bytes).
SHA-256: `042168f216cab30250b5276b423f8d6e16bbe0e7dfddfa2b593aa63fa2a66505`.

[Download release 0.9.1](https://github.com/Tspin420/down-stack-/releases/tag/v0.9.1).
[Windows build, regression tests and history verification](https://github.com/Tspin420/down-stack-/actions/runs/43663530758).
[Independent verification of the downloaded public archive](https://github.com/Tspin420/down-stack-/actions/runs/43663874107).

## Regression results

The Windows Server 2025 runner used Godot 4.6.3 Standard, with downloaded editor
and export templates checked against the repository's pinned SHA-256 values.
All twelve regression suites completed successfully:

| Suite | Assertions | Failures |
| --- | ---: | ---: |
| Core | 41 | 0 |
| Gravity | 90 | 0 |
| Garbage | 230 | 0 |
| Earlier features / update | 69 | 0 |
| Input | 72 | 0 |
| Settings | 75 | 0 |
| Controller drop | 51 | 0 |
| Input audit | 216 | 0 |
| Hidden buffer | 89 | 0 |
| Desktop | 25 | 0 |
| Visual behavior | 106 | 0 |
| Menu | 53 | 0 |
| **Total** | **1117** | **0** |

The input audit included 8,192 seeded stress events. Five-process loopback
multiplayer passed: spectator host, two boards owned by one participant, a
remote player, a spectator, and deliberate rejection of a protocol-7 client.
Attacks of 1, 2, 4, 24 and 55 rows reached their intended receiver intact.
This was a local multi-process test, not a two-household internet test.

The Windows x64 release exported successfully, and the actual exported Windows
executable completed its 120-frame headless startup. ZIP integrity, source-commit
metadata and checksum validation passed. The build came from a clean checkout.

## Source and history cleanup

All four maintained branches received rewritten histories. The preparation
reviewed 21 original commits and cleaned 40 historical file versions. A second
scan covered 262 unique file objects reachable from the rewritten branch tips,
including the release commit, and reported zero restricted-name matches.
Commit messages and historical filenames were checked as well.

Before adding release-version metadata, each rewritten branch tip had exactly
the same file tree as its already-cleaned predecessor. For the release candidate,
additional comparisons confirmed that game scripts, assets, tests, licenses,
main scene and Windows shortcut source were unchanged. Only release metadata,
documentation and a visual-capture helper's baseline commit ID changed.

The current source scan checked 109 text files and embedded strings in 20 binary
files with no document exemptions and no matches. The superseded 0.9.0 release
and tag were retired only after the tested 0.9.1 replacement was published.
Temporary maintenance and verification branches were removed afterward.

This covers maintained branch/tag history and the current downloadable package.
GitHub-managed pull-request references, cached views, previous Actions logs and
copies already downloaded or cloned elsewhere were not purged.

## Independent package inspection

The first resource-inspection helper reported a pass but emitted NUL-character
conversion warnings when treating binary data as text. That helper was not game
code and was not included in the release. Its resource-inspection result is
superseded by the separate raw-byte verification below.

A second, read-only job downloaded the published archive afresh and matched both
the pinned SHA-256 above and its attached checksum. It checked all 17 ZIP members.
It then started Godot with the actual exported PCK as the main resource pack,
extracted all 75 contained files through binary-safe Base64, and scanned their
original bytes and filenames in Python. The compiled main script and packaged
project configuration were explicitly required to be present.

**Result: 17 archive members and 75 pack resources checked; zero restricted-name
matches, zero decoding warnings. The published game package was not modified.**
This was a text/embedded-string audit, not a visual or audible content review.

## Updating and remaining playtesting

For the game, extract the entire 0.9.1 ZIP to a new folder and keep the executable
and PCK together. Saved controls and Sprint records remain in the existing
per-user data folder. Recreate the desktop shortcut from the new game folder.

For source development, make a fresh clone after the history rewrite. Do not
merge or force-push an old clone into the cleaned repository.

Gameplay remains at 120 Hz, remote snapshots at 20 Hz, VSync disabled and rendering
uncapped. Network protocol remains 8. This maintenance release adds no new online
service integration. Automated results found no regression in their coverage;
physical controller playtesting, real internet connections and measured display
frame pacing still require target-PC testing. The Windows executable is unsigned.
