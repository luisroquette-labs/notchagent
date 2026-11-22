---
name: delete-comment
description: Audit NotchAgent code comments and tighten the per-file comment ratchet.
---

# Delete comments

1. Read each comment with its surrounding code. Classify it as tautology, stale, excuse, or decision record. Keep required Swift tool directives, shebangs, license notices, and build obligations.
2. Delete tautologies and stale comments. Delete excuses and open an issue for the underlying implementation defect. Move decisions to `docs/adr/` with context and consequences.
3. Run `python3 Tools/check-comments.py --baseline` to inspect the remaining comment fingerprint baseline. Update `Tools/comment-baseline.json` only after reviewing each changed comment. The lint rejects new comment lines even if an old comment is removed in the same file.
4. Run `python3 Tools/check-comments.py`, focused tests, and the repository's delivery checks. Report removed lines, remaining debt, issues, and ADRs.
