# Downstack project identity

Downstack is a free, independently developed falling-block puzzle game made as
a personal hobby project with AI assistance. Describe its actual controls,
features and implemented rules, rather than presenting it as another publisher's
product or a certified recreation. Use quad or four-line clear for that move.

The rules and numeric settings are documented in RULES_REFERENCE.md,
SOFT_DROP_REFERENCE.md and BUFFER_NOTES.md. This wording cleanup does not change
gameplay, settings, networking, artwork, audio or the project's license.

## Wording checks

Run `python tools/check_branding.py`. Every tracked text file and filename is
checked, including research, comments, tests, configuration and legal notices.
There is no research-document or checker exemption. The check also searches
embedded UTF-8 and UTF-16 strings in binary files; it does not inspect pixels or
listen to audio. Its search terms use character escapes to avoid self-matches.

Keep the project license and required third-party notices intact. A failed text
check is not permission to remove a required notice. New packages run the check
before export. Historical commits and previously published downloads are not
silently rewritten by changes to the current files.
