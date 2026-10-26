#!/bin/bash

set -ouex pipefail

log() {
	echo "=== $* ==="
}

#######################################################################
# Setup Repositories
#######################################################################

log "Enable Copr repos..."
COPR_REPOS=(
    atim/starship # starship
    bigjapka/VeraCrypt # veracrypt
	errornointernet/packages
	heus-sueh/packages                # for matugen/swww
	leloubil/wl-clip-persist
	lionheartp/Hyprland # provides packages needed for niri on Fedora 44
	lukasfr/ripgrep-all # ripgrep-all
	tofik/sway
	ulysg/xwayland-satellite
	yalter/niri
	scottames/ghostty
	supervillain/i2pd # i2pd
)

for repo in "${COPR_REPOS[@]}"; do
	# Try to enable the repo, but don't fail the build if it doesn't support this Fedora version
	if ! dnf5 -y copr enable "$repo" 2>&1; then
		log "Warning: Failed to enable COPR repo $repo (may not support Fedora $RELEASE)"
	fi
done

#######################################################################
## Install Packages
#######################################################################

# Note that these fedora font packages are preinstalled in the
# bluefin-dx image, along with the SymbolsNerdFont which doesn't
# have an associated fedora package:
#
#   adobe-source-code-pro-fonts
#   google-droid-sans-fonts
#   google-noto-sans-cjk-fonts
#   google-noto-color-emoji-fonts
#   jetbrains-mono-fonts
#
# Because the nerd font symbols are mapped correctly, we can get
# nerd font characters anywhere.
FONTS=(
	fira-code-fonts
	fontawesome-fonts-all
	google-noto-emoji-fonts
    mathjax-typewriter-fonts
    overpass-fonts
    overpass-mono-fonts
    polarsys-b612-fonts
    urw-base35-fonts
)

# Niri compositor + Noctalia Shell dependencies.
# Noctalia provides natively: bar, launcher, notifications, lockscreen,
# wallpaper management, palette/theming, session/logout, and brightness/volume IPC.
# Only the backends and tools those features call into are listed here.
NIRI_PKGS=(
	# --- Compositor + Noctalia shell ---
	niri
	noctalia-git

	# --- Audio backend (Noctalia volume IPC calls into these) ---
	pamixer            # volume backend called by Noctalia IPC
	pavucontrol        # graphical mixer for fine-grained audio control
	playerctl          # media player control
	wireplumber        # PipeWire session manager (required)

	# --- Brightness backend ---
	brightnessctl      # Noctalia brightness IPC calls this

	# --- Screenshot (not built into Noctalia) ---
	grim
	slurp
	swappy

	# --- Clipboard ---
	cliphist
	wl-clipboard
	wl-clip-persist

	# --- Bluetooth backend ---
	blueman
	bluez
	bluez-tools
	gnome-bluetooth

	# --- System services ---
	gvfs               # virtual filesystem (file dialogs, portals)
	upower             # power/battery info
	libgtop2           # system resource metrics (Noctalia sysmon widget)
	network-manager-applet  # NM tray indicator

	# --- Portals (required for screen sharing, file pickers, theming) ---
	xdg-desktop-portal-gtk
	# xdg-desktop-portal-gnome

	# --- XWayland bridge ---
	xwayland-satellite
	wget2
)

# chrome etc are installed as flatpaks. We generally prefer that
# for most things with GUIs, and homebrew for CLI apps. This list is
# only special GUI apps that need to be installed at the system level.
ADDITIONAL_SYSTEM_APPS=(
    aria2
    asciidoc
    bat
    dnscrypt-proxy
	fcitx5
	fcitx5-configtool
	fcitx5-gtk
	fcitx5-qt
    fd-find
	ghostty
    glow
	i2pd
	kcm-fcitx5
	moreutils
    neovim
	pandoc
    parallel
    poppler
    poppler-utils
    proxychains-ng
    ripgrep
	ripgrep-all
    sshuttle
	starship
	thunar
	thunar-volman
	thunar-archive-plugin
	tor
	veracrypt
    xorriso
    # --- software-defined-radio ---
    hackrf
    hackrf-devel
    rtl-sdr
    rtl-sdr-devel
    SoapySDR
    SoapySDR-devel
    soapy-rtlsdr
    soapy-uhd
    texlive-collection-fontsrecommended
    texlive-collection-xetex
    texlive-latex
    uhd
    uhd-devel
)

#######################################################################
# Variant-specific additions
#######################################################################

VARIANTS_APPS=(
	toolbox
	qt5ct
	qt6ct
)

# On Bazzite variants, toolbox may have been removed by the base image.
# Re-install it so it is always available on Bazzite builds.
log "Installing variant-specific packages..."
# shellcheck source=/dev/null
source /etc/os-release

if [[ "${ID}" == "bazzite" || "${ID_LIKE}" == *"bazzite"* ]]; then
	log "Bazzite variant detected — installing variant packages..."
	# we do all package installs in one rpm-ostree command
	# so that we create minimal layers in the final image
	dnf5 install --skip-broken --setopt=install_weak_deps=False -y \
		"${FONTS[@]}" \
		"${NIRI_PKGS[@]}" \
		"${ADDITIONAL_SYSTEM_APPS[@]}" \
		"${VARIANTS_APPS[@]}"
else
	log "Non-Bazzite variant — skipping variant packages."
	log "Bazzite variant detected — installing variant packages..."
	# we do all package installs in one rpm-ostree command
	# so that we create minimal layers in the final image
	dnf5 install --setopt=install_weak_deps=False -y \
		"${FONTS[@]}" \
		"${NIRI_PKGS[@]}" \
		"${ADDITIONAL_SYSTEM_APPS[@]}"
fi

# Packages to exclude - common to all versions
EXCLUDED_PACKAGES=(
    cosign
    fedora-bookmarks
    fedora-chromium-config
    fedora-chromium-config-gnome
    firefox
    firefox-langpacks
    gnome-extensions-app
    gnome-shell-extension-background-logo
    gnome-software
    gnome-software-rpm-ostree
    gnome-terminal-nautilus
    podman-docker
    yelp
)

# Remove excluded packages if they are installed
if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    readarray -t INSTALLED_EXCLUDED < <(rpm -qa --queryformat='%{NAME}\n' "${EXCLUDED_PACKAGES[@]}" 2>/dev/null || true)
    if [[ "${#INSTALLED_EXCLUDED[@]}" -gt 0 ]]; then
        dnf5 -y remove "${INSTALLED_EXCLUDED[@]}"
    else
        echo "No excluded packages found to remove."
    fi
fi

#######################################################################
### Disable repositeories so they aren't cluttering up the final image

log "Disable Copr repos to get rid of clutter..."
for repo in "${COPR_REPOS[@]}"; do
	dnf5 -y copr disable "$repo"
done

### Install fcitx5-lotus from GitHub Releases

log "Installing fcitx5-lotus from GitHub releases..."

FCITX5_LOTUS_REPO="LotusInputMethod/fcitx5-lotus"
FEDORA_VERSION="$(rpm -E %fedora)"

# Map the Fedora version to the release artifact suffix used by fcitx5-lotus
case "${FEDORA_VERSION}" in
	42) FCITX5_LOTUS_RPM_SUFFIX="42" ;;
	43) FCITX5_LOTUS_RPM_SUFFIX="43" ;;
	44) FCITX5_LOTUS_RPM_SUFFIX="44" ;;
	*)  FCITX5_LOTUS_RPM_SUFFIX="rawhide" ;;
esac

# Get the latest release tag (e.g. "v3.4.0") and strip the leading "v" for the filename
FCITX5_LOTUS_TAG="$(
	curl -fsSL "https://api.github.com/repos/${FCITX5_LOTUS_REPO}/releases/latest" \
		| grep -oP '"tag_name":\s*"\K[^"]+'
)"
FCITX5_LOTUS_VERSION="${FCITX5_LOTUS_TAG#v}"

# Construct the download URL from the known filename pattern
FCITX5_LOTUS_RPM_FILENAME="fcitx5-lotus-${FCITX5_LOTUS_VERSION}-1.x86_64.${FCITX5_LOTUS_RPM_SUFFIX}.rpm"
FCITX5_LOTUS_RPM_URL="https://github.com/${FCITX5_LOTUS_REPO}/releases/download/${FCITX5_LOTUS_TAG}/${FCITX5_LOTUS_RPM_FILENAME}"
FCITX5_LOTUS_RPM_TMP="/tmp/${FCITX5_LOTUS_RPM_FILENAME}"

log "Downloading fcitx5-lotus ${FCITX5_LOTUS_VERSION} for Fedora ${FEDORA_VERSION}..."
curl -fsSL -o "${FCITX5_LOTUS_RPM_TMP}" "${FCITX5_LOTUS_RPM_URL}"

log "Installing ${FCITX5_LOTUS_RPM_FILENAME}..."
dnf5 install --setopt=install_weak_deps=False -y "${FCITX5_LOTUS_RPM_TMP}"

rm -f "${FCITX5_LOTUS_RPM_TMP}"
