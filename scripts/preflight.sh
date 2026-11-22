#!/usr/bin/env bash
set -euo pipefail
python3 Tools/check-comments.py
python3 -m unittest Tools/test_check_comments.py
NOTCHAGENT_DISABLE_PAID_PROBES=1 swift test
