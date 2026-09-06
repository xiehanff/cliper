#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
skip_build=false

if [[ "${1:-}" == "--skip-build" ]]; then
  skip_build=true
fi

full_version="$(sed -n 's/^version:[[:space:]]*//p' "$repo_root/pubspec.yaml" | head -n 1)"
if [[ -z "$full_version" ]]; then
  printf 'Missing version in pubspec.yaml\n' >&2
  exit 1
fi

bundle_dir="$repo_root/build/linux/x64/release/bundle"
deb_output_dir="$repo_root/build/linux/x64/release"
deb_artifact="$deb_output_dir/cliper_${full_version}_amd64.deb"

if [[ "$skip_build" == false ]]; then
  fvm flutter build linux --release
fi

if [[ ! -x "$bundle_dir/cliper" ]]; then
  printf 'Linux release bundle not found: %s\n' "$bundle_dir" >&2
  printf 'Run fvm flutter build linux --release first.\n' >&2
  exit 1
fi

if ! command -v dpkg-deb >/dev/null 2>&1; then
  printf 'dpkg-deb is required to build the Debian package\n' >&2
  exit 1
fi

pkg_root="$(mktemp -d)"
trap 'rm -rf "$pkg_root"' EXIT

install -d \
  "$pkg_root/DEBIAN" \
  "$pkg_root/opt" \
  "$pkg_root/usr/share/applications" \
  "$pkg_root/usr/share/icons"

cp -a "$bundle_dir" "$pkg_root/opt/cliper"
rm -rf "$pkg_root/opt/cliper/share"
cp -a "$repo_root/linux/icons/hicolor" "$pkg_root/usr/share/icons/"
sed 's|^Exec=cliper$|Exec=/opt/cliper/cliper|' \
  "$repo_root/linux/com.cliper.app.desktop" > \
  "$pkg_root/usr/share/applications/com.cliper.app.desktop"

cat > "$pkg_root/DEBIAN/control" <<EOF
Package: cliper
Version: $full_version
Section: utils
Priority: optional
Architecture: amd64
Maintainer: xiehan <noreply@example.com>
Depends: libc6, libgtk-3-0, libglib2.0-0, libstdc++6
Description: CLIPER clipboard history manager
 A Flutter clipboard history manager packaged for Linux.
EOF

cat > "$pkg_root/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f /usr/share/icons/hicolor/ || true
fi
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database /usr/share/applications/ || true
fi
chmod +x /opt/cliper/cliper
exit 0
EOF
chmod 755 "$pkg_root/DEBIAN/postinst"

mkdir -p "$deb_output_dir"
dpkg-deb --build --root-owner-group "$pkg_root" "$deb_artifact"
printf 'DEB release package: %s\n' "$deb_artifact"
