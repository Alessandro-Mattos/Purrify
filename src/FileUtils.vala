/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 Alessandro Mattos
 */

namespace Purrify {
    public class FileUtils : Object {
        public static bool path_exists (string path) {
            return File.new_for_path (path).query_exists ();
        }

        public static uint64 directory_size (string path) {
            var file = File.new_for_path (path);
            return file_size (file);
        }

        private static uint64 file_size (File file) {
            uint64 total = 0;

            try {
                FileInfo info = file.query_info (
                    "standard::type,standard::size",
                    FileQueryInfoFlags.NOFOLLOW_SYMLINKS
                );

                if (info.get_file_type () != FileType.DIRECTORY) {
                    return info.get_size ();
                }

                FileEnumerator enumerator = file.enumerate_children (
                    "standard::name,standard::type,standard::size",
                    FileQueryInfoFlags.NOFOLLOW_SYMLINKS
                );

                FileInfo? child_info;
                while ((child_info = enumerator.next_file ()) != null) {
                    var child = file.get_child (child_info.get_name ());
                    total += file_size (child);
                }
            } catch (Error error) {
                // If we cannot read it, we do not pretend. Move on.
            }

            return total;
        }

        public static bool remove_recursively (string path, out string error_message) {
            error_message = "";
            var file = File.new_for_path (path);
            return remove_file_recursively (file, out error_message);
        }

        private static bool remove_file_recursively (File file, out string error_message) {
            error_message = "";

            try {
                FileInfo info = file.query_info (
                    "standard::type",
                    FileQueryInfoFlags.NOFOLLOW_SYMLINKS
                );

                if (info.get_file_type () == FileType.DIRECTORY) {
                    FileEnumerator enumerator = file.enumerate_children (
                        "standard::name,standard::type",
                        FileQueryInfoFlags.NOFOLLOW_SYMLINKS
                    );

                    FileInfo? child_info;
                    while ((child_info = enumerator.next_file ()) != null) {
                        var child = file.get_child (child_info.get_name ());
                        string child_error;

                        if (!remove_file_recursively (child, out child_error)) {
                            error_message = child_error;
                            return false;
                        }
                    }
                }

                file.delete ();
                return true;
            } catch (Error error) {
                error_message = error.message;
                return false;
            }
        }

        public static string format_bytes (uint64 bytes) {
            double value = (double) bytes;
            string[] units = { "B", "KB", "MB", "GB", "TB" };
            int unit = 0;

            while (value >= 1024.0 && unit < units.length - 1) {
                value /= 1024.0;
                unit++;
            }

            if (unit == 0) {
                return "%s %s".printf (bytes.to_string (), units[unit]);
            }

            return "%.1f %s".printf (value, units[unit]);
        }
    }
}
