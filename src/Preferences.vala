/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 Alessandro Mattos
 */

namespace Purrify {
    public class ScanOptions : Object {
        public bool include_apps_cache { get; set; default = true; }
        public bool include_folders { get; set; default = true; }
        public bool include_duplicates { get; set; default = false; }
    }

    public class Preferences : Object {
        private string preferences_path;

        public Preferences () {
            string config_dir = Path.build_filename (Environment.get_user_config_dir (), "purrify");
            DirUtils.create_with_parents (config_dir, 0700);
            preferences_path = Path.build_filename (config_dir, "preferences.ini");
        }

        public ScanOptions load_scan_options () {
            var options = new ScanOptions ();
            var key_file = new KeyFile ();

            try {
                key_file.load_from_file (preferences_path, KeyFileFlags.NONE);

                if (has_key (key_file, "scan", "include_apps_cache")
                    || has_key (key_file, "scan", "include_folders")) {
                    options.include_apps_cache = get_bool (key_file, "scan", "include_apps_cache", true);
                    options.include_folders = get_bool (key_file, "scan", "include_folders", true);
                    options.include_duplicates = get_bool (key_file, "scan", "include_duplicates", false);

                    if (!options.include_folders) {
                        options.include_duplicates = false;
                    }
                } else {
                    options = ScanOptionGroups.from_legacy (
                        get_bool (key_file, "scan", "include_core", true),
                        get_bool (key_file, "scan", "include_flatpak", true),
                        get_bool (key_file, "scan", "include_downloads", true),
                        get_bool (key_file, "scan", "include_duplicates", false),
                        get_bool (key_file, "scan", "include_developer_tools", false)
                    );
                }
            } catch (Error error) {
                // First launch should be useful, not adventurous.
            }

            return options;
        }

        public void save_scan_options (ScanOptions options) {
            var key_file = new KeyFile ();
            key_file.set_boolean ("scan", "include_apps_cache", options.include_apps_cache);
            key_file.set_boolean ("scan", "include_folders", options.include_folders);
            key_file.set_boolean ("scan", "include_duplicates", options.include_duplicates);

            try {
                key_file.save_to_file (preferences_path);
            } catch (Error error) {
            }
        }

        private bool get_bool (KeyFile key_file, string group, string key, bool fallback) {
            try {
                return key_file.get_boolean (group, key);
            } catch (Error error) {
                return fallback;
            }
        }

        private bool has_key (KeyFile key_file, string group, string key) {
            try {
                return key_file.has_key (group, key);
            } catch (Error error) {
                return false;
            }
        }
    }
}
