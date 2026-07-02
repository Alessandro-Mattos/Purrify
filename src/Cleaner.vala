/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 Alessandro Mattos
 */

using Gee;

namespace Purrify {
    public class CleanupResult : Object {
        public int cleaned_count { get; set; default = 0; }
        public int failed_count { get; set; default = 0; }
        public int cleaned_commands { get; set; default = 0; }
        public uint64 cleaned_bytes { get; set; default = 0; }
        public ArrayList<string> failure_messages { get; private set; }

        public CleanupResult () {
            failure_messages = new ArrayList<string> ();
        }
    }

    public class CommandResult : Object {
        public bool success { get; set; default = false; }
        public string error_message { get; set; default = ""; }
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
            if (is_descendant_of (normalized, flatpak_apps_dir)) {
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

        // Host command, allowlisted and confirmed. No sneaky "just one little command".
        public CommandResult run_command (CleaningTarget target) {
            var result = new CommandResult ();
            string? command_stdout;
            string? command_stderr;
            int status;

            try {
                if (!is_allowed_command (target)) {
                    result.success = false;
                    result.error_message = _("Command is not in Purrify's allowed command list.");
                    return result;
                }

                string[] argv = { target.command_program };
                foreach (string arg in target.command_args) {
                    argv += arg;
                }

                argv = FileUtils.wrap_host_command_args (argv);

                Process.spawn_sync (
                    null,
                    argv,
                    null,
                    SpawnFlags.SEARCH_PATH,
                    null,
                    out command_stdout,
                    out command_stderr,
                    out status
                );

                result.success = status == 0;

                if (!result.success) {
                    result.error_message = (command_stderr != null && command_stderr.strip () != "")
                        ? command_stderr.strip ()
                        : _("The command exited with an error.");
                }
            } catch (Error error) {
                result.success = false;
                result.error_message = error.message;
            }

            return result;
        }

        private bool is_allowed_command (CleaningTarget target) {
            if (target.command_program != "flatpak" || target.command_args.length != 3) {
                return false;
            }

            return target.command_args[0] == "uninstall"
                && target.command_args[1] == "--unused"
                && target.command_args[2] == "-y";
        }
    }
}
