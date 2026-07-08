/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 Alessandro Mattos
 */

using Gee;

namespace Purrify {
    public class CleanupResult : Object {
        public int cleaned_count { get; set; default = 0; }
        public int failed_count { get; set; default = 0; }
        public uint64 cleaned_bytes { get; set; default = 0; }
        public ArrayList<string> failure_messages { get; private set; }

        public CleanupResult () {
            failure_messages = new ArrayList<string> ();
        }
    }

    public class Cleaner : Object {
        public CleanupResult clean (ArrayList<CleaningTarget> selected) {
            var result = new CleanupResult ();

            foreach (var target in selected) {
                string error_message;

                if (!is_allowed_removal_path (target.path, out error_message)) {
                    result.failed_count++;
                    result.failure_messages.add (_("%s: %s").printf (target.title, error_message));
                    stderr.printf ("Refused to clean %s: %s\n", target.path, error_message);
                    continue;
                }

                if (FileUtils.remove_recursively (target.path, out error_message)) {
                    result.cleaned_count++;
                    result.cleaned_bytes += target.size_bytes;
                } else {
                    result.failed_count++;
                    result.failure_messages.add (_("%s: %s").printf (target.title, error_message));
                    stderr.printf ("Failed to clean %s: %s\n", target.path, error_message);
                }
            }

            return result;
        }

        private bool is_allowed_removal_path (string path, out string error_message) {
            error_message = "";

            if (path.strip () == "") {
                error_message = _("Empty paths cannot be removed.");
                return false;
            }

            string home_dir = Environment.get_home_dir ();
            string? normalized = File.new_for_path (path).get_path ();

            if (normalized == null || normalized == "/" || normalized == home_dir) {
                error_message = _("Refusing to remove a broad system or home path.");
                return false;
            }

            string[] exact_allowed = {
                Path.build_filename (home_dir, ".cache", "thumbnails"),
                Path.build_filename (home_dir, ".local", "share", "Trash", "files"),
                Path.build_filename (home_dir, ".local", "share", "Trash", "info"),
                Path.build_filename (home_dir, ".cache", "pip"),
                Path.build_filename (home_dir, ".npm", "_cacache"),
                Path.build_filename (home_dir, ".cache", "yarn")
            };

            foreach (string allowed in exact_allowed) {
                if (normalized == allowed) {
                    return true;
                }
            }

            string flatpak_apps_dir = Path.build_filename (home_dir, ".var", "app");
            if (is_flatpak_cache_path (normalized, flatpak_apps_dir)) {
                return true;
            }

            string cache_dir = Path.build_filename (home_dir, ".cache");
            if (is_crash_reports_path (normalized, cache_dir)) {
                return true;
            }

            foreach (string root in get_surface_roots ()) {
                if (is_descendant_of (normalized, root)) {
                    return true;
                }
            }

            error_message = _("Path is outside Purrify's allowed cleanup locations.");
            return false;
        }

        private string[] get_surface_roots () {
            string[] roots = {};
            string? downloads = Environment.get_user_special_dir (UserDirectory.DOWNLOAD);
            string? desktop = Environment.get_user_special_dir (UserDirectory.DESKTOP);
            string? documents = Environment.get_user_special_dir (UserDirectory.DOCUMENTS);

            if (downloads != null) {
                roots += downloads;
            }

            if (desktop != null) {
                roots += desktop;
            }

            if (documents != null) {
                roots += documents;
            }

            return roots;
        }

        private bool is_descendant_of (string path, string root) {
            return path.has_prefix (root + Path.DIR_SEPARATOR_S) && path != root;
        }

        private bool is_crash_reports_path (string path, string cache_dir) {
            if (!is_descendant_of (path, cache_dir)) {
                return false;
            }

            string suffix = Path.DIR_SEPARATOR_S + "Crash Reports";
            return path.has_suffix (suffix) || path.index_of (suffix + Path.DIR_SEPARATOR_S) >= 0;
        }

        private bool is_flatpak_cache_path (string path, string flatpak_apps_dir) {
            string root = flatpak_apps_dir + Path.DIR_SEPARATOR_S;
            if (!path.has_prefix (root)) {
                return false;
            }

            string relative = path.substring (root.length);
            string[] parts = relative.split (Path.DIR_SEPARATOR_S);
            return parts.length >= 2 && parts[0] != "" && parts[1] == "cache";
        }
    }
}
