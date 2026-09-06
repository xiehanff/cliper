%{!?app_version:%global app_version 1.1.6}
%{!?app_release:%global app_release 1}

Name:           cliper
Version:        %{app_version}
Release:        %{app_release}%{?dist}
Summary:        CLIPER clipboard history manager
License:        Proprietary
URL:            https://github.com/xiehanff/cliper
Source0:        cliper-bundle.tar.gz
Source1:        cliper-icons.tar.gz
Source2:        com.cliper.app.desktop

BuildArch:      x86_64
BuildRequires:  patchelf
Requires:       gtk3
Requires:       glib2
Requires:       libstdc++

%description
CLIPER is a Flutter desktop clipboard history manager packaged for Linux.

%prep

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/opt/cliper
mkdir -p %{buildroot}/usr/share/applications
mkdir -p %{buildroot}/usr/share/icons

tar -xzf %{SOURCE0} -C %{buildroot}/opt/cliper --strip-components=1
tar -xzf %{SOURCE1} -C %{buildroot}/usr/share/icons

# Flutter's Linux bundle can contain build-machine RUNPATH entries. Replace
# them with paths that remain valid after installation under /opt/cliper.
patchelf --set-rpath '$ORIGIN/lib' %{buildroot}/opt/cliper/cliper
find %{buildroot}/opt/cliper/lib -type f -name '*.so*' \
  -exec patchelf --set-rpath '$ORIGIN' {} +

# Desktop integration is installed in the standard system locations below.
rm -rf %{buildroot}/opt/cliper/share
sed 's|^Exec=cliper$|Exec=/opt/cliper/cliper|' %{SOURCE2} > \
  %{buildroot}/usr/share/applications/com.cliper.app.desktop

%post
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t /usr/share/icons/hicolor >/dev/null 2>&1 || :
fi
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database /usr/share/applications >/dev/null 2>&1 || :
fi

%postun
if [ "$1" -eq 0 ]; then
  if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t /usr/share/icons/hicolor >/dev/null 2>&1 || :
  fi
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database /usr/share/applications >/dev/null 2>&1 || :
  fi
fi

%files
/opt/cliper
%dir /usr/share/applications
/usr/share/applications/com.cliper.app.desktop
/usr/share/icons/hicolor

%changelog
* Thu Oct 15 2026 xiehan <xiehan@users.noreply.github.com> - 1.1.6-1
- Linux packaging aligned with plume-pdf deb/rpm workflow.
