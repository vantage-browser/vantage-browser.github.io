#!/bin/sh
set -eu

repo="vantage-browser/vant"
install_dir="${VANT_INSTALL_DIR:-$HOME/.local/bin}"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
applications_dir="$data_home/applications"
icons_root="$data_home/icons/hicolor"
icon_dir="$icons_root/512x512/apps"
desktop_name="cv.vantage_browser.Vantage.desktop"
icon_name="cv.vantage_browser.Vantage.png"
asset="vant-source.tar.gz"
requested_version="${VANT_VERSION:-latest}"

usage() {
  cat <<'EOF'
Vantage Browser installer

Usage:
  install.sh          Install the latest Vantage release for the current user
  install.sh --help   Show this help

Environment:
  VANT_INSTALL_DIR    Override the binary directory (default: ~/.local/bin)
  VANT_VERSION        Install an exact tag, for example v0.1.0
EOF
}

case "${1:-}" in
  "") ;;
  -h|--help) usage; exit 0 ;;
  *) echo "Vantage installer: unknown option: $1" >&2; usage >&2; exit 2 ;;
esac
[ "$(id -u)" -ne 0 ] || { echo "Vantage installer: run as your desktop user, not with sudo." >&2; exit 1; }
[ "$(uname -s)" = "Linux" ] || { echo "Vantage installer: Linux is currently required." >&2; exit 1; }

echo "Installing Vantage build and runtime dependencies..."
if command -v pacman >/dev/null 2>&1; then
  sudo pacman -S --needed base-devel pkgconf python gtk4 webkitgtk-6.0 sqlite \
    gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav
elif command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl build-essential pkg-config python3 \
    libgtk-4-dev libwebkitgtk-6.0-dev libsqlite3-dev \
    gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav
elif command -v dnf >/dev/null 2>&1; then
  sudo dnf install -y gcc-c++ make pkgconf-pkg-config python3 gtk4-devel webkitgtk6.0-devel sqlite-devel \
    gstreamer1-plugins-base gstreamer1-plugins-good gstreamer1-plugins-bad-free
  for package in gstreamer1-plugins-ugly-free gstreamer1-plugin-libav; do
    sudo dnf install -y "$package" || echo "Vantage installer: optional media package $package is unavailable; continuing." >&2
  done
elif command -v zypper >/dev/null 2>&1; then
  sudo zypper --non-interactive install gcc-c++ make pkg-config python3 gtk4-devel \
    webkit2gtk-6_0-devel sqlite3-devel gstreamer-plugins-base gstreamer-plugins-good gstreamer-plugins-bad
  for package in gstreamer-plugins-ugly gstreamer-plugins-libav; do
    sudo zypper --non-interactive install "$package" || echo "Vantage installer: optional media package $package is unavailable; continuing." >&2
  done
else
  echo "Vantage installer: Arch, Omarchy, Debian, Ubuntu, Fedora and openSUSE are currently supported." >&2
  exit 1
fi

case "$requested_version" in
  latest) base="https://github.com/$repo/releases/latest/download" ;;
  v[0-9]*.[0-9]*.[0-9]*) base="https://github.com/$repo/releases/download/$requested_version" ;;
  *) echo "Vantage installer: VANT_VERSION must be a release tag such as v0.1.0." >&2; exit 1 ;;
esac
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT INT TERM

echo "Downloading immutable Vantage release source..."
curl --proto '=https' --tlsv1.2 -fL "$base/$asset" -o "$tmp/$asset"
curl --proto '=https' --tlsv1.2 -fL "$base/version.txt" -o "$tmp/version.txt"
curl --proto '=https' --tlsv1.2 -fL "$base/checksums.txt" -o "$tmp/checksums.txt"
(cd "$tmp" && sha256sum -c checksums.txt)
version="$(tr -d '\r\n' < "$tmp/version.txt")"
case "$version" in v[0-9]*.[0-9]*.[0-9]*) ;; *) echo "Vantage installer: invalid release version." >&2; exit 1;; esac
[ "$requested_version" = latest ] || [ "$requested_version" = "$version" ] || { echo "Vantage installer: release version mismatch." >&2; exit 1; }

mkdir "$tmp/source"
tar -xzf "$tmp/$asset" -C "$tmp/source" --strip-components=1
echo "Building Vantage $version against this system's WebKitGTK..."
make -C "$tmp/source"
[ "$("$tmp/source/build/vant" --version)" = "Vantage Browser ${version#v}" ] || { echo "Vantage installer: built version mismatch." >&2; exit 1; }

mkdir -p "$install_dir" "$applications_dir" "$icon_dir"
install -m 0755 "$tmp/source/build/vant" "$install_dir/.vant.new"
mv -f "$install_dir/.vant.new" "$install_dir/vant"
install -m 0644 "$tmp/source/packaging/$icon_name" "$icon_dir/$icon_name"
install -m 0644 "$tmp/source/packaging/$desktop_name" "$applications_dir/$desktop_name"
printf '%s\n' "$version" > "$data_home/vantage-browser-installed-version.new"
mv -f "$data_home/vantage-browser-installed-version.new" "$data_home/vantage-browser-installed-version"
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$applications_dir" >/dev/null 2>&1 || true
command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f "$icons_root" >/dev/null 2>&1 || true

echo "Installed Vantage Browser $version. Open it from your application launcher."
case ":${PATH:-}:" in *":$install_dir:"*) ;; *) echo "Command-line use requires $install_dir in PATH.";; esac
