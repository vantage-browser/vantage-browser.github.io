#!/bin/sh
set -eu

purge=false
case "${1:-}" in "") ;; --purge) purge=true;; -h|--help) echo "usage: uninstall.sh [--purge]"; exit 0;; *) echo "Vantage uninstaller: unknown option: $1" >&2; exit 2;; esac
[ "$(id -u)" -ne 0 ] || { echo "Vantage uninstaller: run as your desktop user, not with sudo." >&2; exit 1; }

install_dir="${VANT_INSTALL_DIR:-$HOME/.local/bin}"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
applications_dir="$data_home/applications"
icons_root="$data_home/icons/hicolor"

rm -f "$install_dir/vant" "$install_dir/vant.previous"
rm -f "$applications_dir/cv.vantage_browser.Vantage.desktop"
rm -f "$icons_root/512x512/apps/cv.vantage_browser.Vantage.png"
rm -f "$data_home/vantage-browser-installed-version"
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$applications_dir" >/dev/null 2>&1 || true
command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f "$icons_root" >/dev/null 2>&1 || true

if $purge; then
  rm -rf "$data_home/vantage-browser" "$config_home/vantage-browser"
  echo "Uninstalled Vantage Browser and removed its local profile."
else
  echo "Uninstalled Vantage Browser. Local browser data was preserved."
  echo "Use --purge to remove history, bookmarks, sessions and settings."
fi
