#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PACKAGE_NAME="cliper"
APP_ID="com.cliper.app"
INSTALL_DIR="/opt/${PACKAGE_NAME}"
OUTPUT_DIR="${ROOT_DIR}/dist"
BUILD_ROOT="${ROOT_DIR}/build/linux/deb"
STAGING_DIR="${BUILD_ROOT}/pkg"
CONTROL_DIR="${STAGING_DIR}/DEBIAN"
BUNDLE_DIR="${ROOT_DIR}/build/linux/x64/release/bundle"

version_line="$(grep '^version:' "${ROOT_DIR}/pubspec.yaml")"
version_value="${version_line#version: }"
package_version="${version_value%%+*}"
package_revision="${version_value##*+}"
if [[ "${package_revision}" == "${version_value}" ]]; then
  package_revision="1"
fi

deb_file="${OUTPUT_DIR}/${PACKAGE_NAME}_${package_version}-${package_revision}_amd64.deb"

rm -rf "${STAGING_DIR}"
mkdir -p \
  "${CONTROL_DIR}" \
  "${STAGING_DIR}${INSTALL_DIR}" \
  "${STAGING_DIR}/usr/bin" \
  "${STAGING_DIR}/usr/share/applications" \
  "${STAGING_DIR}/usr/share/icons/hicolor/256x256/apps"

fvm flutter build linux --release

cp -R "${BUNDLE_DIR}/." "${STAGING_DIR}${INSTALL_DIR}/"
cp "${ROOT_DIR}/assets/icon.png" \
  "${STAGING_DIR}/usr/share/icons/hicolor/256x256/apps/${APP_ID}.png"
ln -s "${INSTALL_DIR}/${PACKAGE_NAME}" "${STAGING_DIR}/usr/bin/${PACKAGE_NAME}"

cat > "${CONTROL_DIR}/control" <<EOF
Package: ${PACKAGE_NAME}
Version: ${package_version}-${package_revision}
Section: utils
Priority: optional
Architecture: amd64
Maintainer: CLIPER
Depends: libgtk-3-0, libkeybinder-3.0-0
Description: CLIPER clipboard history manager
 Desktop clipboard history manager for Linux Wayland/GNOME.
EOF

cat > "${STAGING_DIR}/usr/share/applications/${APP_ID}.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=CLIPER
Comment=Clipboard history manager
Exec=/usr/bin/${PACKAGE_NAME}
Icon=${APP_ID}
Terminal=false
Categories=Utility;
StartupNotify=true
StartupWMClass=${APP_ID}
X-GNOME-WMClass=${APP_ID}
EOF

cat > "${CONTROL_DIR}/postinst" <<'EOF'
#!/usr/bin/env bash
set -e

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database /usr/share/applications || true
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f /usr/share/icons/hicolor >/dev/null 2>&1 || true
fi
EOF

cat > "${CONTROL_DIR}/postrm" <<'EOF'
#!/usr/bin/env bash
set -e

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database /usr/share/applications || true
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f /usr/share/icons/hicolor >/dev/null 2>&1 || true
fi
EOF

chmod 0755 "${CONTROL_DIR}/postinst" "${CONTROL_DIR}/postrm"

mkdir -p "${OUTPUT_DIR}"
dpkg-deb --build --root-owner-group "${STAGING_DIR}" "${deb_file}"

printf 'Built %s\n' "${deb_file}"
