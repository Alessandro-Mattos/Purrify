/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 Alessandro Mattos
 */

using Gee;

namespace Purrify {
    public class CleanupHistoryEntry : Object {
        public string timestamp { get; set; default = ""; }
        public uint64 bytes { get; set; default = 0; }
        public int items { get; set; default = 0; }
        public int commands { get; set; default = 0; }
        public int failures { get; set; default = 0; }
    }

    public class Stats : Object {
        private string stats_path;

        public Stats () {
            string data_dir = Environment.get_user_data_dir ();
            DirUtils.create_with_parents (data_dir, 0700);
            stats_path = Path.build_filename (data_dir, "purrify-stats.ini");
        }

        public uint64 get_total_freed_bytes () {
            var key_file = load_key_file ();

            try {
                return key_file.get_uint64 ("stats", "total_freed_bytes");
            } catch (Error error) {
                return 0;
            }
        }

        public void add_freed_bytes (uint64 bytes) {
            uint64 total = get_total_freed_bytes () + bytes;
            var key_file = load_key_file ();
            key_file.set_uint64 ("stats", "total_freed_bytes", total);
            save_key_file (key_file);
        }

        public void record_cleanup (uint64 bytes, int items, int commands, int failures) {
            add_freed_bytes (bytes);

            var key_file = load_key_file ();
            int count = 0;

            try {
                count = key_file.get_integer ("stats", "history_count");
            } catch (Error error) {
                count = 0;
            }

            count++;
            key_file.set_integer ("stats", "history_count", count);

            var now = new DateTime.now_local ();
            string group = "history-%d".printf (count);
            key_file.set_string (group, "timestamp", now.format ("%Y-%m-%d %H:%M"));
            key_file.set_uint64 (group, "bytes", bytes);
            key_file.set_integer (group, "items", items);
            key_file.set_integer (group, "commands", commands);
            key_file.set_integer (group, "failures", failures);
            save_key_file (key_file);
        }

        public ArrayList<CleanupHistoryEntry> get_recent_history (int limit = 3) {
            var entries = new ArrayList<CleanupHistoryEntry> ();
            var key_file = load_key_file ();
            int count = 0;

            try {
                count = key_file.get_integer ("stats", "history_count");
            } catch (Error error) {
                return entries;
            }

            for (int index = count; index >= 1 && entries.size < limit; index--) {
                string group = "history-%d".printf (index);

                try {
                    var entry = new CleanupHistoryEntry ();
                    entry.timestamp = key_file.get_string (group, "timestamp");
                    entry.bytes = key_file.get_uint64 (group, "bytes");
                    entry.items = key_file.get_integer (group, "items");
                    entry.commands = key_file.get_integer (group, "commands");
                    entry.failures = key_file.get_integer (group, "failures");
                    entries.add (entry);
                } catch (Error error) {
                }
            }

            return entries;
        }

        private KeyFile load_key_file () {
            var key_file = new KeyFile ();

            try {
                key_file.load_from_file (stats_path, KeyFileFlags.NONE);
            } catch (Error error) {
            }

            return key_file;
        }

        private void save_key_file (KeyFile key_file) {
            try {
                key_file.save_to_file (stats_path);
            } catch (Error error) {
            }
        }
    }
}
