#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PROJECT_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"

exec godot --headless --log-file /tmp/tartarus-godot.log --path "$PROJECT_DIR" --script res://scripts/dev/validate_project.gd --check-only
