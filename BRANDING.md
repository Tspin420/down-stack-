# Downstack project identity and release review

Downstack is a free, independently developed falling-block puzzle game, made as
a personal hobby project with AI assistance. It is intended to remain free to
download and play. Do not present it as an official product, certified ruleset,
or endorsed recreation of another publisher's game.

## Wording and sources

Use Downstack for the product name and falling-block puzzle game for its genre.
Use quad or four-line clear for that move. Describe the actual documented
handling, gravity and attack rules instead of promising exact parity with a
named commercial title. Do not change gameplay merely to change terminology.

Factual research titles, source URLs and their verification limits are retained
in [docs/RESEARCH_SOURCES.md](docs/RESEARCH_SOURCES.md). Those historical
comparisons are development records, not the current gameplay specification or
marketing copy. The current rules remain in RULES_REFERENCE.md,
SOFT_DROP_REFERENCE.md and BUFFER_NOTES.md. Do not remove or falsify provenance
to imply that published research was never consulted.

Keep LICENSE.txt and all third-party notices in licenses/ intact. Any future
third-party asset or dependency needs its actual permission and attribution
requirements reviewed; renaming it is not a substitute for permission.

## Automated text audit

Run `python tools/check_branding.py` from a checkout. The check examines tracked
text and filenames, including source strings, documentation, configuration,
workflows, tests and text-format assets. A read-only GitHub Actions workflow
runs it on pushes and pull requests, and the Windows packager runs it before
exporting. The script's built-in self-tests check both matches and false positives.

The explicit exceptions are the development source record, the checker's own
search patterns, LICENSE.txt and licenses/. Exceptions preserve accurate
research attribution and legal notices; they are not a claim that every use of
a third-party name is prohibited. New exceptions require a specific reason.

A passing result is not an audit of pixels, audio, binary metadata, Git history,
other branches, hosted release descriptions or existing download archives.
Review those surfaces separately. Historical tags and published assets are not
silently rewritten by an editorial change on main. A new reviewed release is
needed to distribute the updated documentation; old downloads remain old builds.

## Scope and remaining review

This cleanup changes documentation and packaging checks, not the runtime game,
its settings, network protocol, artwork, audio or licenses. Existing gameplay
validation results remain historical results, not newly rerun engine tests.

Branding cleanup is not legal clearance. Names and branding raise different
questions from rights in code, art, sound and visual presentation. A text search
cannot determine whether the game's overall presentation infringes another
party's rights. Review the actual assets and presentation before a broad public
release, and obtain qualified legal advice when rights are uncertain.

General references:
- U.S. Copyright Office, games: https://www.copyright.gov/register/tx-games.html
- USPTO, trademark/patent/copyright distinctions: https://www.uspto.gov/trademarks/basics/trademark-patent-copyright
