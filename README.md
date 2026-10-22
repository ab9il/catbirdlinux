<div align="center">

# 🌊 Catbirdlinux

**An immutable, daily-built Wayland desktop powered by Niri, based on Bluefin.**

</div>

---

## 📖 About

**Catbird Linux** is an image-based, general purpose Linux operating system, powered by [bootc](https://github.com/bootc-dev/bootc) and [Universal Blue](https://universal-blue.org/). It offers a pre-configured, atomic OS image that arranges your windows with [Niri](https://github.com/YaLTeR/niri). It is a modern, infinite-scrollable tiling Wayland compositor.

With daily automated builds ensuring you always have the latest security patches and upstream updates, `Catbird Linux` provides a highly customized yet remarkably stable desktop experience.

### ✨ Key Pillars

- 🌀 **Scrollable Tiling**: Navigate windows on an infinite horizontal ribbon using Niri, augmented by the [Noctalia](https://github.com/noctalia-dev/noctalia) desktop shell.
- 🛡️ **Daily Security & Atomic Upgrades**: Images are rebuilt daily (`cron: "05 10 * * *"`) pulling the latest upstream updates and packages. Updates apply atomically in the background.
- 🇻🇳 **Vietnamese Input**: Out-of-the-box support via `fcitx5-lotus`, automatically tracking the latest GitHub releases during the image build.
- ⚡ **Curated Wayland Toolstack**: Ships with essential tools like Ghostty, Waybar, Rofi-Wayland/Fuzzel, SwayNC, Thunar, and more.

---

## 💿 Install by Rebasing

You must first install either the official release of Bluefin, or any other flavor of Fedora Atomic or Universal Blue Linux, then rebase to this image. You will thereby get the necessary verification keys and trust policies. The second rebase task fully installs and verifies authenticity of this customized Bluefin version:

Rebase with the "bootc switch" command for the latest images:

```bash
sudo bootc switch --enforce-container-sigpolicy ghcr.io/ab9il/catbirdlinux:latest
```
```
```

Reboot and your switch to this customized version of Bluefin will be complete.

> [!WARNING]
> Switching your image via `bootc switch` will replace your current OS base. Your home directory (`~`) and `/etc` are preserved. Always back up important data before rebasing.

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

## 🇻🇳 Vietnamese Input Configuration

The image ships with [**fcitx5-lotus**](https://github.com/LotusInputMethod/fcitx5-lotus), compiled directly from the latest release for your Fedora base.

**Post-install setup:**
Add the following to `~/.config/environment.d/fcitx5.conf` (create if missing):
```ini
XMODIFIERS=@im=fcitx
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
SDL_IM_MODULE=fcitx
GLFW_IM_MODULE=ibus

```

Then launch **fcitx5-configtool**, add **Lotus**, and choose your preferred typing method (Telex / VNI / VIQR). Make sure to configure `fcitx5 &` to auto-start in your Niri configuration!

**More Languages are in the works. Check back again later for updates.**

---

## 🏗️ Under the Hood

### Repository Structure

```text
catbirdlinux/
├── Containerfile           # Image definitions pulling from uBlue bases
├── build_files/
│   └── build.sh            # Injects packages, configs, and COPR repos
├── system_files/           # System-wide overrides (/etc, /usr)
├── .github/workflows/
│   └── build.yml           # CI that builds images daily and on-push
└── image-template.env      # Build environment metadata
```

### Security & Signing

Images are built automatically by GitHub Actions and cryptographically signed using `cosign`. You can verify the integrity of any downloaded image using the public key `cosign.pub` included in this repository.

---

## History

The Project began in 2019 as "Pemmican Linux" for web scraping and data science. It encompassed several successive respins of Linux Mint, Ubuntu, and Debian, and expanded in scope to include web development and media creation tools. Original distribution was via bit torrents and traditional iso files. It carried tools useful for data science, open source intelligence gathering, and creating multimedia content.

This is the fourth generation of Catbird Linux. Since adopting image-based Linux architecture and containerized / universal application packaging, it is a system which can truly operate on the frontiers of general purpose computing. The system is now distributed as a lightweight bootc image, and users install whatever software they want via Flatpaks, AppImages, Homebrew, or Docker images.
## 🤝 Community & Support

Built with ❤️ on top of [Universal Blue](https://universal-blue.org), [Bluefin](https://projectbluefin.io), and [Nirifin](https://github.com/im6h/nirifin).

- 💬 [Universal Blue Forums](https://universal-blue.discourse.group/)
- 📖 [bootc Discussion](https://github.com/bootc-dev/bootc/discussions)

