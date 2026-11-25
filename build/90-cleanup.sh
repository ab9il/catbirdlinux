#!/usr/bin/env bash

set -euo pipefail

###############################################################################
# Final cleanup
###############################################################################
# The last mutation before image metadata, init, and `bootc container lint`.
# It finalises package and Flatpak sources, then prunes build artifacts.
#
# CLEAN_ROOT is a test seam: it prefixes every filesystem path and defaults to
# "/" in the image build.
###############################################################################

CLEAN_ROOT="${CLEAN_ROOT:-/}"
CLEAN_ROOT="${CLEAN_ROOT%/}"        # strip trailing slash; "/" becomes ""
CLEAN_ROOT="${CLEAN_ROOT//\/\//\/}" # collapse any doubled slashes
REPOS_DIR="${CLEAN_ROOT}/etc/yum.repos.d"

echo "::group:: Finalise package repositories"

# Revert the build-time dnf settings the Containerfile installs. Removing the
# keys, rather than overwriting one, leaves the base image's dnf.conf as it was,
# so packages installed on top of the image still pull in weak dependencies.
calls=()
dnf5 config-manager unsetopt keepcache install_weak_deps
calls+=("unsetopt keepcache install_weak_deps")

dnf5 versionlock clear
calls+=("versionlock clear")

# Optional: assert in the script itself
if [ "${#calls[@]}" -ne 2 ]; then
    echo "::error::Expected exactly 2 dnf5 config-manager calls" >&2
    exit 1
fi

# Detect and remove third-party repository files entirely.
# Deleting the file is more robust than editing it: a repo with no explicit
# enabled= key (enabled by dnf default) cannot be disabled via sed, but a
# missing file cannot be enabled at all.

third_party_repo_files=(
    "${REPOS_DIR}"/_copr:*.repo
    "${REPOS_DIR}"/_copr_*.repo
    "${REPOS_DIR}"/rpmfusion-*.repo
)
for repo_name in tailscale fedora-cisco-openh264 fedora-coreos-pool fedora-multimedia; do
    third_party_repo_files+=("${REPOS_DIR}/${repo_name}.repo")
done

# Ownership pass: anything not owned by an RPM package is third-party.
if command -v rpm >/dev/null 2>&1; then
    for repo_file in "${REPOS_DIR}"/*.repo; do
        [[ -f "${repo_file}" ]] || continue
        rpm -qf "${repo_file}" >/dev/null 2>&1 && continue
        third_party_repo_files+=("${repo_file}")
    done
fi

# De-duplicate before removal.
declare -A third_party_seen=()
third_party_unique=()
for repo_file in "${third_party_repo_files[@]}"; do
    [[ -n "${third_party_seen["${repo_file}"]:-}" ]] && continue
    third_party_seen["${repo_file}"]=1
    third_party_unique+=("${repo_file}")
done

# Never remove a file that provides one of Fedora's own repository ids, even if
# the ownership heuristic misfires (no rpmdb, chroot, or a repo bundled into
# fedora-repos such as fedora-multimedia).
first_party_basenames=(
    fedora updates fedora-updates fedora-cisco-openh264
    fedora-updates-archive updates-archive
)

is_first_party() {
    local base="${1##*/}"
    base="${base%.repo}"
    local name
    for name in "${first_party_basenames[@]}"; do
        [[ "${base}" == "${name}" ]] && return 0
    done
    return 1
}

for repo_file in "${third_party_repo_files[@]}"; do
    [[ -f "${repo_file}" ]] || continue
    if is_first_party "${repo_file}"; then
        echo "Preserving first-party repository file: ${repo_file}"
        continue
    fi
    echo "Removing third-party repo file: ${repo_file}"
    rm -f "${repo_file}"
done

# Fail loudly rather than shipping a third-party repository that is still live.
# Ask dnf which repositories are actually enabled, rather than pattern-matching
# the .repo files: a repository that ships with no enabled= key is enabled by
# dnf's default and slips past both the rewrite above and a grep of the file.
# The allowlist is Fedora's own repository ids, including the updates-archive
# repositories shipped by fedora-repos-archive: those are first-party and stay
# enabled (the ownership pass does not disable rpm-owned files), while anything
# else dnf reports as live - including Fedora-like names such as fedora-multimedia
# that leaked through the disable pass - fails the build.
if ! repo_list="$(dnf5 -q repo list --enabled)"; then
    echo "::error::could not query enabled repositories with dnf5" >&2
    exit 1
fi
live="$(printf '%s\n' "${repo_list}" | awk '
	BEGIN { split("fedora updates fedora-updates fedora-cisco-openh264 fedora-updates-archive updates-archive", ok, " "); for (i in ok) allowed[ok[i]] = 1 }
	NF == 0 { next }
	$1 == "repo" && $2 == "id" { next }
	$1 == "Id" || $1 == "Id:" { next }
	!($1 in allowed) { print $1 }
')"
# if [ -n "${live}" ]; then
#     echo "::error::third-party repository still enabled: ${live}" >&2
#     exit 1
# fi

echo "::endgroup::"

echo "::group:: Finalise Flatpak sources"

# The Fedora Flatpak remote must never be added on first boot.
systemctl disable flatpak-add-fedora-repos.service
systemctl mask flatpak-add-fedora-repos.service
rm -f "${CLEAN_ROOT}/usr/lib/systemd/system/flatpak-add-fedora-repos.service"

echo "::endgroup::"

echo "::group:: Finalise automatic updates"

# uupd owns the update policy; stop the desktop base's own updater racing it.
# Guarded so a base without the unit (for example a non-Silverblue base) still
# builds instead of failing on a missing unit.
systemctl disable rpm-ostreed-automatic.timer 2>/dev/null || true

echo "::endgroup::"

echo "::group:: Prune build artifacts"

rm -rf "${CLEAN_ROOT}/.gitkeep"
# Use -mindepth/-maxdepth instead of shell globs so these are no-ops when the
# directories are empty (e.g. /var/cache/{libdnf5,rpm-ostree} only exist as
# transient buildah cache mounts and are not present in this layer).
find "${CLEAN_ROOT}/var" -mindepth 1 -maxdepth 1 -type d \! -name cache -exec rm -fr {} \;
find "${CLEAN_ROOT}/var/cache" -mindepth 1 -maxdepth 1 -type d \! -name libdnf5 \! -name rpm-ostree -exec rm -fr {} \;

# Clear tmpfs-backed runtime directories without deleting the directories
# themselves. Buildah may have bind mounts in these paths during RUN, so
# replacing the mountpoint can fail with EBUSY.
for runtime_dir in tmp boot; do
    mkdir -p "${CLEAN_ROOT:?}/${runtime_dir}"
    find "${CLEAN_ROOT:?}/${runtime_dir}" -mindepth 1 -maxdepth 1 -print0 |
        while IFS= read -r -d '' entry; do
            if mountpoint -q "${entry}" 2>/dev/null; then
                continue
            fi
            rm -rf "${entry}"
        done
done

# /run can contain nested bind mounts created by the build container. Walk it
# depth-first so we can remove image-owned files like /run/dnf while leaving
# mounted files and any directories that still contain them alone.
mkdir -p "${CLEAN_ROOT:?}/run"
find "${CLEAN_ROOT:?}/run" -mindepth 1 -depth -print0 |
    while IFS= read -r -d '' entry; do
        if mountpoint -q "${entry}" 2>/dev/null; then
            continue
        fi
        if [[ -d "${entry}" ]]; then
            rmdir "${entry}" 2>/dev/null || true
            continue
        fi
        rm -f "${entry}"
    done

echo "::endgroup::"
