#!/bin/sh
set -eu

repo="vantage-browser/vant"
install_dir="${VANT_INSTALL_DIR:-$HOME/.local/bin}"
applications_dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
icons_root="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor"
icon_dir="$icons_root/512x512/apps"
desktop_name="cv.vantage_browser.Vantage.desktop"
icon_name="cv.vantage_browser.Vantage.png"

usage() {
  cat <<'EOF'
Vantage Browser installer

Usage:
  install.sh          Install Vantage for the current user
  install.sh --help   Show this help

Environment:
  VANT_INSTALL_DIR    Override the binary directory (default: ~/.local/bin)
  VANT_VERSION        Install a release tag instead of latest
EOF
}

case "${1:-}" in
  "") ;;
  -h|--help) usage; exit 0 ;;
  *) echo "Vantage installer: unknown option: $1" >&2; usage >&2; exit 2 ;;
esac

if [ "$(id -u)" -eq 0 ]; then
  echo "Vantage installer: run this installer as your desktop user, not with sudo." >&2
  exit 1
fi
[ "$(uname -s)" = "Linux" ] || { echo "Vantage installer: Linux is currently required." >&2; exit 1; }
case "$(uname -m)" in x86_64|amd64) arch="x86_64";; *) echo "Vantage installer: only x86_64 is currently packaged." >&2; exit 1;; esac

echo "Checking Vantage runtime dependencies..."
if command -v pacman >/dev/null 2>&1; then
  if ! sudo pacman -S --needed gtk4 webkitgtk-6.0 sqlite gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav; then
    echo "Vantage installer: package installation failed." >&2
    if command -v omarchy >/dev/null 2>&1; then
      echo "Run 'omarchy update', reboot if requested, then run this installer again." >&2
    else
      echo "Update the complete Arch system, then run this installer again." >&2
    fi
    exit 1
  fi
elif command -v apt-get >/dev/null 2>&1; then
  if ! apt-cache show libwebkitgtk-6.0-4 >/dev/null 2>&1; then
    echo "Vantage installer: this Debian/Ubuntu release does not provide WebKitGTK 6.0." >&2
    echo "Use a newer supported release or build Vantage against its available WebKitGTK version." >&2
    exit 1
  fi
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl libgtk-4-1 libwebkitgtk-6.0-4 \
    libsqlite3-0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav
else
  echo "Vantage installer: this preview installer currently supports Arch, Omarchy, Debian and Ubuntu." >&2
  echo "Other Linux systems can build Vantage from source." >&2
  exit 1
fi

asset="vant-linux-${arch}.tar.gz"
version="${VANT_VERSION:-latest}"
if [ "$version" = "latest" ]; then base="https://github.com/$repo/releases/latest/download"; else base="https://github.com/$repo/releases/download/$version"; fi
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT INT TERM

echo "Downloading Vantage..."
curl --proto '=https' --tlsv1.2 -fL "$base/$asset" -o "$tmp/$asset"
curl --proto '=https' --tlsv1.2 -fL "$base/checksums.txt" -o "$tmp/checksums.txt"
expected="$(awk -v file="$asset" '$2 == file || $2 == "*" file {print $1}' "$tmp/checksums.txt")"
[ -n "$expected" ] || { echo "Vantage installer: checksum missing for $asset." >&2; exit 1; }
actual="$(sha256sum "$tmp/$asset" | awk '{print $1}')"
[ "$actual" = "$expected" ] || { echo "Vantage installer: checksum mismatch." >&2; exit 1; }
tar -xzf "$tmp/$asset" -C "$tmp" vant

mkdir -p "$install_dir" "$applications_dir" "$icon_dir"
install -m 0755 "$tmp/vant" "$install_dir/.vant.new"
mv -f "$install_dir/.vant.new" "$install_dir/vant"
curl --proto '=https' --tlsv1.2 -fL "https://vant.cx/assets/images/vant.png" -o "$icon_dir/.${icon_name}.new"
mv -f "$icon_dir/.${icon_name}.new" "$icon_dir/$icon_name"
curl --proto '=https' --tlsv1.2 -fL "https://vant.cx/downloads/$desktop_name" -o "$applications_dir/.${desktop_name}.new"
mv -f "$applications_dir/.${desktop_name}.new" "$applications_dir/$desktop_name"

command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$applications_dir" >/dev/null 2>&1 || true
command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f "$icons_root" >/dev/null 2>&1 || true

echo "Installed Vantage Browser. Open it from your application launcher."
case ":${PATH:-}:" in *":$install_dir:"*) ;; *) echo "Command-line use requires $install_dir in PATH.";; esac
