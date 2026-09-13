#!/bin/sh
set -eu

repo="vantage-browser/vant"
install_dir="${VANT_INSTALL_DIR:-$HOME/.local/bin}"
binary="$install_dir/vant"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
applications_dir="$data_home/applications"
icons_root="$data_home/icons/hicolor"
icon_dir="$icons_root/512x512/apps"
desktop_name="cv.vantage_browser.Vantage.desktop"
icon_name="cv.vantage_browser.Vantage.png"
asset="vant-source.tar.gz"
requested_version="${VANT_VERSION:-latest}"

case "${1:-}" in "") ;; -h|--help) echo "usage: update.sh"; exit 0;; *) echo "Vantage updater: unknown option: $1" >&2; exit 2;; esac
[ "$(id -u)" -ne 0 ] || { echo "Vantage updater: run as your desktop user, not with sudo." >&2; exit 1; }
[ -f "$binary" ] && [ ! -L "$binary" ] || { echo "Vantage updater: no regular installation found at $binary." >&2; exit 1; }
command -v make >/dev/null 2>&1 && command -v pkg-config >/dev/null 2>&1 || { echo "Vantage updater: build tools are missing; rerun https://vant.cx/install.sh." >&2; exit 1; }
pkg-config --exists gtk4 webkitgtk-6.0 sqlite3 || { echo "Vantage updater: development packages are missing; rerun https://vant.cx/install.sh." >&2; exit 1; }

case "$requested_version" in
  latest) base="https://github.com/$repo/releases/latest/download" ;;
  v[0-9]*.[0-9]*.[0-9]*) base="https://github.com/$repo/releases/download/$requested_version" ;;
  *) echo "Vantage updater: VANT_VERSION must be a release tag such as v0.1.0." >&2; exit 1 ;;
esac
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT INT TERM
curl --proto '=https' --tlsv1.2 -fL "$base/$asset" -o "$tmp/$asset"
curl --proto '=https' --tlsv1.2 -fL "$base/version.txt" -o "$tmp/version.txt"
curl --proto '=https' --tlsv1.2 -fL "$base/checksums.txt" -o "$tmp/checksums.txt"
(cd "$tmp" && sha256sum -c checksums.txt)
version="$(tr -d '\r\n' < "$tmp/version.txt")"
case "$version" in v[0-9]*.[0-9]*.[0-9]*) ;; *) echo "Vantage updater: invalid release version." >&2; exit 1;; esac
[ "$requested_version" = latest ] || [ "$requested_version" = "$version" ] || { echo "Vantage updater: release version mismatch." >&2; exit 1; }

mkdir "$tmp/source"
tar -xzf "$tmp/$asset" -C "$tmp/source" --strip-components=1
echo "Building Vantage $version against this system's WebKitGTK..."
make -C "$tmp/source"
[ "$("$tmp/source/build/vant" --version)" = "Vantage Browser ${version#v}" ] || { echo "Vantage updater: built version mismatch." >&2; exit 1; }

cp "$binary" "$binary.previous.new"
chmod 0755 "$binary.previous.new"
mv -f "$binary.previous.new" "$binary.previous"
install -m 0755 "$tmp/source/build/vant" "$binary.new"
mv -f "$binary.new" "$binary"
mkdir -p "$applications_dir" "$icon_dir"
install -m 0644 "$tmp/source/packaging/$icon_name" "$icon_dir/$icon_name"
install -m 0644 "$tmp/source/packaging/$desktop_name" "$applications_dir/$desktop_name"
printf '%s\n' "$version" > "$data_home/vantage-browser-installed-version.new"
mv -f "$data_home/vantage-browser-installed-version.new" "$data_home/vantage-browser-installed-version"
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$applications_dir" >/dev/null 2>&1 || true
command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f "$icons_root" >/dev/null 2>&1 || true
echo "Updated Vantage Browser to $version. Reopen it to use the new version."
