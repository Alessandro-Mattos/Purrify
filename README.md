# Purrify

![Purrify logo](FullLogo.png)

**Yes, the kitten cleaner.**

Purrify is a beautiful cleanup app for elementary OS. It helps you to keep your desktop clean and tidy , removing thumbnail caches, Trash, Flatpak leftovers, duplicate downloads, empty folders, and a few developer caches.

It is not a magic optimizer, and it does not pretend to know better than you. It scans, shows what it found, and asks before cleaning.

## Why

Desktop cleaners are easy to get wrong. Purrify keeps the scope narrow on purpose:

- no `sudo`
- no background daemon
- no system cleanup
- no telemetry
- no network service
- no automatic deletion
- no broad `$HOME` permission in the Flatpak manifest

The app only works with user-space locations that it explicitly scans. So you don't have to worry about accidental data loss or system crashes like other cleaners.
And Yes, I wrote it because BleachBit messes with my system too... AGAIN (i know your pain).
We have a safe alternative.

## Support the Project 🐾

If Purrify made your Linux life a little less cursed, you can **[Feed the Cat](https://donate.stripe.com/cNicN42EFbHy54Y0P1frW00)**.

Stars on [GitHub](https://github.com/alessandro-mattos/purrify) also help. Cats like attention. Developers pretend they don't, but they do.

## What It Can Review

- thumbnail cache
- local Trash
- Flatpak leftovers in `~/.var/app`
- installed Flatpak app caches
- unused Flatpak runtimes
- duplicate files in Downloads, matched by content hash
- empty folders and broken shortcuts in common user folders
- pip, npm, and Yarn caches
- per-app crash reports

## Build

Install the local development dependencies on elementary OS or Ubuntu-like systems:

```bash
sudo apt update
sudo apt install valac meson ninja-build libgtk-4-dev libgranite-7-dev libgee-0.8-dev
```

Build and run:

```bash
meson setup build --prefix=/usr/local
meson compile -C build
./build/src/purrify
```

Or use:

```bash
./scripts/dev-run.sh
```

## Flatpak

The manifest is at:

```txt
flatpak/io.github.alessandro_mattos.Purrify.yml
```

Build and install locally:

```bash
flatpak-builder --user --install --force-clean build-dir flatpak/io.github.alessandro_mattos.Purrify.yml
flatpak run io.github.alessandro_mattos.Purrify
```

Purrify targets `io.elementary.Platform//8` and `io.elementary.Sdk//8`.

## Note

Purrify is elementary-first, but not elementary-only. It uses GTK 4, Granite, standard symbolic icons, and a Wayland-first Flatpak setup with X11 fallback.



## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
