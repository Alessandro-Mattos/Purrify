/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 Alessandro Mattos
 */

namespace Purrify {
    public class ScanOptions : Object {
        public bool include_core { get; set; default = true; }
        public bool include_flatpak { get; set; default = true; }
        public bool include_downloads { get; set; default = true; }
        public bool include_duplicates { get; set; default = false; }
        public bool include_developer_tools { get; set; default = false; }
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
                options.include_core = get_bool (key_file, "scan", "include_core", true);
                options.include_flatpak = get_bool (key_file, "scan", "include_flatpak", true);
                options.include_downloads = get_bool (key_file, "scan", "include_downloads", true);
                options.include_duplicates = get_bool (key_file, "scan", "include_duplicates", false);
                options.include_developer_tools = get_bool (key_file, "scan", "include_developer_tools", false);
            } catch (Error error) {
                // First launch should be useful, not adventurous.
            }

            return options;
        }

        public void save_scan_options (ScanOptions options) {
            var key_file = new KeyFile ();
            key_file.set_boolean ("scan", "include_core", options.include_core);
            key_file.set_boolean ("scan", "include_flatpak", options.include_flatpak);
            key_file.set_boolean ("scan", "include_downloads", options.include_downloads);
            key_file.set_boolean ("scan", "include_duplicates", options.include_duplicates);
            key_file.set_boolean ("scan", "include_developer_tools", options.include_developer_tools);

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
    }
}
