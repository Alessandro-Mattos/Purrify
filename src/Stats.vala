/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 Alessandro Mattos
 */

namespace Purrify {
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
