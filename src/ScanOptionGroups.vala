/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 Alessandro Mattos
 */

namespace Purrify {
    public class ScanOptionGroups : Object {
        public static ScanOptions from_legacy (
            bool include_core,
            bool include_flatpak,
            bool include_downloads,
            bool include_duplicates,
            bool include_developer_tools
        ) {
            var options = new ScanOptions ();
            options.include_apps_cache = include_core || include_flatpak || include_developer_tools;
            options.include_folders = include_core || include_downloads;
            options.include_duplicates = options.include_folders && include_duplicates;
            return options;
        }

        public static void set_apps_cache_enabled (ScanOptions options, bool active) {
            options.include_apps_cache = active;
        }

        public static void set_folders_enabled (ScanOptions options, bool active) {
            options.include_folders = active;

            if (!active) {
                options.include_duplicates = false;
            }
        }

        public static bool duplicate_review_sensitive (ScanOptions options) {
            return options.include_folders;
        }
    }
}
