#!/usr/bin/env bash
set -e

sudo rm -rf /opt/Antigravity

rm -f "$HOME/.local/share/applications/antigravity2"

update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

echo "Antigravity removed."