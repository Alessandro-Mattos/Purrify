# Purrify

![Purrify logo](Styles/FullLogo.png)

**Purrify: yes, that kitten cleaner.**

Keep your desktop fresh and tidy with a small, careful cleaner for elementary OS. Purrify reviews common user-space clutter, shows what can be removed, and waits for your confirmation before touching anything.

Purrify is written in **Vala**, **GTK 4**, and **Granite**, with **Meson** for builds and **Flatpak** packaging.

> Status: initial release candidate. Before publishing, validate the Flatpak manifest, AppStream metadata, screenshots, and manual test checklist below.

---

## What Purrify Does

- Scans the thumbnail cache: `~/.cache/thumbnails`
- Scans the local Trash:
  - `~/.local/share/Trash/files`
  - `~/.local/share/Trash/info`
- Detects Flatpak leftovers in `~/.var/app`
  - compares local app folders with `flatpak list --app --columns=application`
- Offers unused Flatpak runtime cleanup:
  - `flatpak uninstall --unused`
- Shows an estimated size before cleaning
- Uses checkboxes so the user chooses exactly what to clean
- Shows a confirmation dialog with a compact category summary
- Shows a simple before/after cleanup summary
- Stores local cleanup history
- Reports cleanup failures in the app
- Lets the user choose the scan scope:
  - caches and Trash
  - Flatpak
  - Downloads
  - duplicate review
  - developer tools
- Remembers scan choices locally
- Leaves duplicates unselected by default
- Avoids `sudo`, `pkexec`, daemons, remote backends, analytics, and paid APIs

---

## What Purrify Does Not Do

- It does not clean system files.
- It does not request administrative privileges.
- It does not clean `/var`, global `/tmp`, system logs, APT packages, or kernels.
- It does not run scheduled or automatic cleanup.
- It does not use X11-specific APIs.
- It does not run in the background.
- It does not send telemetry.

These limits are intentional. Purrify is designed to be boring where it matters: safe, local, reviewable, and easy to explain.

---

## Stack

```txt
Language: Vala
UI: GTK 4 + Granite
Build system: Meson
Packaging: Flatpak
Target: elementary OS 7.1+
Display compatibility: Wayland-first, X11 fallback
```

---

## Project Structure

```txt
purrify/
├── data/
│   ├── io.github.alessandro_mattos.Purrify.desktop.in
│   ├── io.github.alessandro_mattos.Purrify.metainfo.xml.in
│   └── icons/hicolor/scalable/apps/io.github.alessandro_mattos.Purrify.svg
├── flatpak/
│   └── io.github.alessandro_mattos.Purrify.yml
├── src/
│   ├── Application.vala
│   ├── MainWindow.vala
│   ├── Scanner.vala
│   ├── Cleaner.vala
│   ├── CleaningTarget.vala
│   ├── FileUtils.vala
│   ├── Preferences.vala
│   └── Stats.vala
├── po/
│   ├── LINGUAS
│   ├── POTFILES
│   └── *.po
├── scripts/
│   └── dev-run.sh
├── Styles/
│   └── FullLogo.png
├── meson.build
├── LICENSE
└── README.md
```

---

## Local Development

On elementary OS or Ubuntu-like systems, install the development dependencies:

```bash
sudo apt update
sudo apt install valac meson ninja-build libgtk-4-dev libgranite-7-dev libgee-0.8-dev
```

Package names can vary slightly between distro versions.

Build and run locally:

```bash
meson setup build --prefix=/usr/local
meson compile -C build
./build/src/purrify
```

Or use the helper script:

```bash
./scripts/dev-run.sh
```

---

## Flatpak Build

The Flatpak manifest lives at:

```txt
flatpak/io.github.alessandro_mattos.Purrify.yml
```

Build and run locally:

```bash
flatpak-builder --user --install --force-clean build-dir flatpak/io.github.alessandro_mattos.Purrify.yml
flatpak run io.github.alessandro_mattos.Purrify
```

The manifest currently targets:

```yaml
runtime: io.elementary.Platform
runtime-version: '8'
sdk: io.elementary.Sdk
```

---

## Wayland and X11

Purrify uses regular GTK APIs and avoids compositor-specific behavior:

- no `Xlib`
- no `xrandr`
- no screen capture
- no global shortcuts
- no external overlays
- no direct window-manager manipulation

The Flatpak manifest uses:

```yaml
finish-args:
  - --socket=wayland
  - --socket=fallback-x11
  - --share=ipc
```

Wayland is the primary path, with X11 available as a compatibility fallback.

---

## Safety Model

Purrify only works in user-space locations and keeps destructive work behind a confirmation dialog.

The cleanup model has three layers:

1. **Safe by default**
   - thumbnail cache
   - local Trash
   - clearly orphaned Flatpak folders

2. **Review first**
   - Downloads cleanup
   - duplicate files
   - app caches
   - developer tool caches

3. **Explicit host command**
   - unused Flatpak runtimes via `flatpak uninstall --unused`
   - still selected and confirmed through the same cleanup flow

Important constraints:

- no deletion without a scan result
- no deletion without user confirmation
- no broad `$HOME` cleanup
- no `--filesystem=home` permission
- no network access
- no telemetry
- no elevated privileges

---

## Publishing Checklist

- Confirm whether `io.github.alessandro_mattos.Purrify` is the final app ID.
- Validate Flatpak permissions in `flatpak/io.github.alessandro_mattos.Purrify.yml`.
- Add real screenshots.
- Test the confirmation flow on a real session.
- Validate AppStream metadata with `appstreamcli`.
- Validate the desktop file with `desktop-file-validate`.
- Check for name or trademark conflicts.
- Run manual tests with:
  - elementary OS 7.1+ on Wayland/Secure Session
  - elementary OS 7.1+ on X11/Classic Session
  - a user with few Flatpak apps
  - a user with many Flatpak apps
  - a user without `~/.var/app`
  - large Downloads folders
  - duplicate files with identical content
  - duplicate names with different content

---

## Roadmap Ideas

- A clearer before/after view
- Group Flatpak leftovers by app
- Open-folder review before deletion
- Explicit dry-run mode
- Visual freed-space meter
- Friendly risk labels such as "Safe", "Review", and "Manual"
- Toast or banner feedback after cleanup
- Human review for the included gettext catalogs: en-US, es, pt-BR, de, fr, and ru

---

## License

MIT.
# Purrify
