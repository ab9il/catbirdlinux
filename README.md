<div align="center">

# 🌊 Catbird Linux

**An immutable, daily-built Wayland desktop powered by Niri, based on Bluefin.**

</div>

---

## 📖 About

Catbird Linux is now adopting atomic / image-based architecture! It comes to
you as a bootc operating system image, assembled similarly to Bluefin and Bazzite,
using shared OCI layers. It is practically unbreakable, since the system core
is built and tested here in the cloud, before deployed to you, while your userpace
applications are separately built, tested, and maintained.

Catbird Linux no longer packs as many tools into the initial download, so you can get
up and going faster. You also have tremendous freedom in the applications you install,
including Podman / Docker containers from any of the popular Linux distributions. With
containers, you can run a mix of apps from various distributions, and even Windows, if
you so choose.

**In other words, you can now run just about anything imaginable.**

<div align="center">

[![Catbird Linux is now image based.](https://github.com/ab9il/AB9IL/raw/master/catbirdlinux-v4.jpg)]()

</div>

### ✨ Key Pillars

- 🐧 **Fedora Linux Core:** This base image uses [Fedora Hummingbird](https://fedoraproject.org/wiki/hummingbird).
- 🌀 **Scrollable Tiling**: Navigate windows on an infinite horizontal ribbon using Niri, augmented by the [Noctalia](https://github.com/noctalia-dev/noctalia) desktop shell.
- 🛡️ **Frequent Security & Atomic Upgrades**: Images are rebuilt daily, pulling the latest upstream updates and packages. Updates apply atomically in the background.

---

### Get this image by _rebasing:_

1. Install Bluefin, Bazzite, Aurora, or any Universal Blue Linux system.
2. Paste and execute this command in the terminal:
3. Allow time for your Homebrew and Flatpak apps to download and install.

```bash
sudo bootc switch --transport registry ghcr.io/ab9il/catbirdlinux:stable
sudo systemctl reboot
```

Then, as your user, in the terminal:

```bash
ujust install-default-apps    # Homebrew: the default Brewfile
ujust install-dev-tools       # Homebrew: the development Brewfile
ujust configure-dev-groups    # add yourself to docker and libvirt
ujust install-config          # re-apply the image defaults, backing up yours
```

First boot unpacks Homebrew and installs the declared Flatpaks; both need a
network connection. Check them with `systemctl status brew-setup.service` and
`systemctl status flatpak-preinstall.service`.

### Switch back / Rollback

To revert to your previous image at any time:
```bash
sudo bootc rollback
```

---

## 🪟 Niri & Noctalia

[**Niri**](https://github.com/YaLTeR/niri) abandons the standard grid layout for a scrollable horizontal workspace. Windows never shrink uncontrollably; instead, they tile into columns that you can scroll through effortlessly.

To make the system immediately usable, `Catbird Linux` pairs Niri with **Noctalia**, a dedicated desktop shell providing:
- An integrated status bar
- Launcher / app switcher
- Native workspace overview for the scrolling layout

---

## 🏗️ Under the Hood

### Repository Structure

```text
catbirdlinux/
├── Containerfile           # Image definitions pulling from uBlue bases
├── build/
│   └── build scripts       # Injects packages, configs, and COPR repos
├── custom/
│   └── brew, config...     # Injects files and configurations
├── .github/workflows/      # CI that builds images daily and on-push
└── iso/                    # build-time metadata for isi creation
└── tests/                  # build0time quality and integrity tests
```

### Image Authenticity and Signing

Images are signed with keyless OIDC via Cosign and GitHub Actions. There is no
key to generate or store.

```bash
cosign verify \
  --certificate-identity-regexp="https://github.com/ab9il/catbirdlinux/.github/workflows/" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/ab9il/catbirdlinux:stable
```

Unsigned images fail the promotion gate, so `main → stable` reports
`release/blocked` until signing is restored.

#### Where the signature is checked

**In CI, on the way to `:stable` — and not verified on the device.** The
promotion gate is the only enforcement point. An installed system pulls its
updates over an unverified transport (`image-info.json`'s `image-ref` is
`ostree-unverified-image:docker://…`), so `bootc upgrade` does not check the
cosign signature.

That is a deliberate statement of what the image can actually do, not an
oversight. Device-side verification runs through
`/etc/containers/policy.json`, which matches a keyless Fulcio certificate on
`subjectEmail` only — mandatory and exact. A GitHub Actions certificate
identifies its workflow in a URI SAN and carries no email, so no policy entry
can match it, and the inherited policy's `""` catch-all
(`insecureAcceptAnything`) would accept the image regardless. A signed-looking
`image-ref` here would verify nothing while implying it verified something.

Making updates verify on the device means signing with a key the policy can
name: publish with a cosign keypair, merge a `sigstoreSigned` scope for your
namespace into the inherited policy (with `jq`, during
[`build/10-overlay.sh`](build/10-overlay.sh) — never by shipping a whole
`policy.json` through `custom/files/`, which freezes every scope you inherited),
add a `registries.d` entry with `use-sigstore-attachments: true` for it, and
flip `IMAGE_REF` back to `ostree-image-signed:`. Validate that on a real
catcatbirdtall before shipping it: a scope that does not match turns `bootc upgrade`
into a hard refusal. `tests/contract/image-signing_test.bats` holds the two
sides together, so changing one without the other fails the suite.

---

#### History

The Project began in 2019 as "Pemmican Linux" for web scraping and data science. It encompassed several successive respins of Linux Mint, Ubuntu, and Debian, and expanded in scope to include web development and media creation tools. Original distribution was via bit torrents and traditional iso files. It carried tools useful for data science, open source intelligence gathering, and creating multimedia content.

This is the fourth generation of Catbird Linux. Since adopting image-based Linux architecture and containerized / universal application packaging, it is a system which can truly operate on the frontiers of general purpose computing. The system is now distributed as a lightweight bootc image, and users install whatever software they want via Flatpaks, AppImages, Homebrew, or Docker images.

### What Makes this System Different?

This image is based on [Project Bluefin](https://projectbluefin.io) and includes these customizations:

#### Added Applications (Runtime):

- **CLI tools (Homebrew)**:
  - Extra bling and conveniences for the Bash shell
  - Cosign (authentication keys for git, etc.)
  - Fzf / Ripgrep / terminal based search tools
  - Tor (The Onion Router)
  - I2P (Invisible Internet Project)
  - Lazygit (git content manager)
  - Lf (file manager)
  - Neovim (text / code editor)
  - Sshuttle (ssh based tunneling / VPN)
  - Uv (Python manager)
- **GUI apps (Flatpak)**:
  - Audacity (audio editor)
  - Bleachbit (system cleaner)
  - Bottles (run Windows apps)
  - Brave (web browser)
  - GIMP (image editor)
  - LibreOffice (office suite)
  - Obsidian (Markdown based note-taking)
  - Shotcut (video editor)
---

#### History

The Project began in 2019 as "Pemmican Linux" for web scraping and data science. It encompassed several successive respins of Linux Mint, Ubuntu, and Debian, and expanded in scope to include web development and media creation tools. Original distribution was via bit torrents and traditional iso files. It carried tools useful for data science, open source intelligence gathering, and creating multimedia content.

This is the fourth generation of Catbird Linux. Since adopting image-based Linux architecture and containerized / universal application packaging, it is a system which can truly operate on the frontiers of general purpose computing. The system is now distributed as a lightweight bootc image, and users install whatever software they want via Flatpaks, AppImages, Homebrew, or Docker images.

### What Makes this System Different?

This image is based on [Project Bluefin](https://projectbluefin.io) and includes these customizations:

#### Added Applications (Runtime):

- **CLI tools (Homebrew)**:
  - Extra bling and conveniences for the Bash shell
  - Cosign (authentication keys for git, etc.)
  - Fzf / Ripgrep / terminal based search tools
  - Tor (The Onion Router)
  - I2P (Invisible Internet Project)
  - Lazygit (git content manager)
  - Lf (file manager)
  - Neovim (text / code editor)
  - Sshuttle (ssh based tunneling / VPN)
  - Uv (Python manager)
- **GUI apps (Flatpak)**:
  - Audacity (audio editor)
  - Bleachbit (system cleaner)
  - Bottles (run Windows apps)
  - Brave (web browser)
  - GIMP (image editor)
  - LibreOffice (office suite)
  - Obsidian (Markdown based note-taking)
  - Shotcut (video editor)
  - Transmission (bit torrent client)
  - VLC (media player)
  - Zathura (PDF reader)

#### Removed or Disabled

- Firefox (web browser)

#### Configuration Changes

- **Desktop Environment:**
  - Niri Scrolling Window Manager with Noctalia.
- **SDR Hardware Drivers:**
  - hackrf
  - hackrf-devel
  - rtl-sdr
  - rtl-sdr-devel
  - SoapySDR
  - SoapySDR-devel
  - soapy-rtlsdr
  - soapy-uhd
  - uhd (You still need to install a binary for your uhd radio.)
  - uhd-devel
- **Timekeeing:** Extra Chrony settings for tighter NTP clock sync.


_Last updated: [2026-11-09]_

## 🤝 Community & Support

Built with ❤️ on top of [Universal Blue](https://universal-blue.org) and [Bluefin](https://projectbluefin.io).

- 💬 [Universal Blue Forums](https://universal-blue.discourse.group/)
- 📖 [bootc Discussion](https://github.com/bootc-dev/bootc/discussions)
- 📖 [Book: The Era of Atomic Linux](https://skywavelinux.com/atomic-linux)

### Learn more

- [Universal Blue](https://universal-blue.org/)
- [bootc](https://containers.github.io/bootc/)
- [Project Bluefin contributing guide](https://docs.projectbluefin.io/contributing/)

### Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).


---
This repository is still under construction!
