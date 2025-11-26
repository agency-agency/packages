# Spec for DMS - uses rpkg macros for git builds

%global debug_package %{nil}
%global version 0.0.git.1440.7bf73ab1
%global pkg_summary DankMaterialShell - Material 3 inspired shell for Wayland compositors

Name:           dms
Epoch:          1
Version:        %{version}
Release:        1%{?dist}
Summary:        %{pkg_summary}

License:        GPL-3.0-only
URL:            https://github.com/AvengeMedia/DankMaterialShell
VCS:            git+https://github.com/AvengeMedia/DankMaterialShell.git#7bf73ab14d6f64beb8967b26e95e26f6c79e35a8:
Source0:        DankMaterialShell-7bf73ab1.tar.gz

# DMS CLI from danklinux latest commit
Source1:        https://github.com/AvengeMedia/danklinux/archive/refs/heads/master.tar.gz

BuildRequires:  git-core
BuildRequires:  rpkg
BuildRequires:  gzip
BuildRequires:  golang >= 1.24
BuildRequires:  make
BuildRequires:  wget

# Core requirements - using quickshell-webengine for web UI support
Requires:       quickshell-webengine
Requires:       dms-cli
Requires:       dgop
Requires:       fira-code-fonts
Requires:       material-symbols-fonts
Requires:       rsms-inter-fonts

# GameScope for optimal WebEngine performance
Recommends:     gamescope

# Core utilities (Highly recommended for DMS functionality)
Recommends:     brightnessctl
Recommends:     cava
Recommends:     cliphist
Recommends:     hyprpicker
Recommends:     matugen
Recommends:     wl-clipboard

# Recommended system packages
Recommends:     NetworkManager
Recommends:     qt6-qtmultimedia
Suggests:       qt6ct

%description
DankMaterialShell (DMS) is a modern Wayland desktop shell built with Quickshell
and optimized for the niri and hyprland compositors. This version uses 
quickshell-webengine to enable React-based web UI components with Material 3 
design.

Features:
- Web-based UI using QtWebEngine (React + Material 3)
- Auto-theming for GTK/Qt apps with matugen
- 20+ customizable widgets
- Process monitoring and notifications
- Clipboard history and dock
- Control center and lock screen
- Comprehensive plugin system
- Hardware-accelerated rendering via GameScope

Includes notifications, app launcher, wallpaper customization, and fully 
customizable with plugins.

%package -n dms-cli
Summary:        DankMaterialShell CLI tool
License:        GPL-3.0-only
URL:            https://github.com/AvengeMedia/danklinux

%description -n dms-cli
Command-line interface for DankMaterialShell configuration and management.
Provides native DBus bindings, NetworkManager integration, and system utilities.

%package -n dgop
Summary:        Stateless CPU/GPU monitor for DankMaterialShell
License:        MIT
URL:            https://github.com/AvengeMedia/dgop
Provides:       dgop

%description -n dgop
DGOP is a stateless system monitoring tool that provides CPU, GPU, memory, and 
network statistics. Designed for integration with DankMaterialShell but can be 
used standalone. This package always includes the latest stable dgop release.

%prep
%setup -T -b 0 -q -n DankMaterialShell

# Extract DankLinux source
tar -xzf %{SOURCE1} -C %{_builddir}

# Download and extract DGOP binary for target architecture
case "%{_arch}" in
  x86_64)
    DGOP_ARCH="amd64"
    ;;
  aarch64)
    DGOP_ARCH="arm64"
    ;;
  *)
    echo "Unsupported architecture: %{_arch}"
    exit 1
    ;;
esac

wget -O %{_builddir}/dgop.gz "https://github.com/AvengeMedia/dgop/releases/latest/download/dgop-linux-${DGOP_ARCH}.gz" || {
  echo "Failed to download dgop for architecture %{_arch}"
  exit 1
}
gunzip -c %{_builddir}/dgop.gz > %{_builddir}/dgop
chmod +x %{_builddir}/dgop

%build
# Build DMS CLI from source
cd %{_builddir}/danklinux-master
make dist

%install
# Install dms-cli binary (built from source) - use architecture-specific path
case "%{_arch}" in
  x86_64)
    DMS_BINARY="dms-linux-amd64"
    ;;
  aarch64)
    DMS_BINARY="dms-linux-arm64"
    ;;
  *)
    echo "Unsupported architecture: %{_arch}"
    exit 1
    ;;
esac

install -Dm755 %{_builddir}/danklinux-master/bin/${DMS_BINARY} %{buildroot}%{_bindir}/dms

# Install dgop binary
install -Dm755 %{_builddir}/dgop %{buildroot}%{_bindir}/dgop

# Install shell files to XDG config location
install -dm755 %{buildroot}%{_sysconfdir}/xdg/quickshell/dms
cp -r * %{buildroot}%{_sysconfdir}/xdg/quickshell/dms/

# Remove build files
rm -rf %{buildroot}%{_sysconfdir}/xdg/quickshell/dms/.git*
rm -f %{buildroot}%{_sysconfdir}/xdg/quickshell/dms/.gitignore
rm -rf %{buildroot}%{_sysconfdir}/xdg/quickshell/dms/.github
rm -f %{buildroot}%{_sysconfdir}/xdg/quickshell/dms/*.spec

%files
%license LICENSE
%doc README.md CONTRIBUTING.md
%{_sysconfdir}/xdg/quickshell/dms/

%files -n dms-cli
%{_bindir}/dms

%files -n dgop
%{_bindir}/dgop

%changelog
* Mon Nov 25 2024 Agency <maintainer@agency-agency.dev> - 0.0.git.1440.7bf73ab1-1
- Update to use quickshell-webengine for web UI support
- Add GameScope recommendation for optimal performance
- Update description to mention React/Material 3 UI
