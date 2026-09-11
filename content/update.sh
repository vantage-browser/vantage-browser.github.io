#!/bin/sh
set -eu

repo="vantage-browser/vant"
install_dir="${VANT_INSTALL_DIR:-$HOME/.local/bin}"
binary="$install_dir/vant"
asset="vant-linux-x86_64.tar.gz"
version="${VANT_VERSION:-latest}"

case "${1:-}" in "") ;; -h|--help) echo "usage: update.sh"; exit 0;; *) echo "Vantage updater: unknown option: $1" >&2; exit 2;; esac
[ "$(id -u)" -ne 0 ] || { echo "Vantage updater: run as your desktop user, not with sudo." >&2; exit 1; }
[ -f "$binary" ] && [ ! -L "$binary" ] || { echo "Vantage updater: no regular installation found at $binary." >&2; exit 1; }
case "$(uname -m)" in x86_64|amd64) ;; *) echo "Vantage updater: only x86_64 is currently packaged." >&2; exit 1;; esac
if [ "$version" = "latest" ]; then base="https://github.com/$repo/releases/latest/download"; else base="https://github.com/$repo/releases/download/$version"; fi
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT INT TERM
curl --proto '=https' --tlsv1.2 -fL "$base/$asset" -o "$tmp/$asset"
curl --proto '=https' --tlsv1.2 -fL "$base/checksums.txt" -o "$tmp/checksums.txt"
expected="$(awk -v file="$asset" '$2 == file || $2 == "*" file {print $1}' "$tmp/checksums.txt")"
[ -n "$expected" ] || { echo "Vantage updater: checksum missing for $asset." >&2; exit 1; }
actual="$(sha256sum "$tmp/$asset" | awk '{print $1}')"
[ "$actual" = "$expected" ] || { echo "Vantage updater: checksum mismatch." >&2; exit 1; }
tar -xzf "$tmp/$asset" -C "$tmp" vant
cp "$binary" "$binary.previous.new"; chmod 0755 "$binary.previous.new"; mv -f "$binary.previous.new" "$binary.previous"
install -m 0755 "$tmp/vant" "$binary.new"; mv -f "$binary.new" "$binary"
echo "Updated Vantage Browser. Reopen it to use the new version."
