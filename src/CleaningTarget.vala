/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 Alessandro Mattos
 */

namespace Purrify {
    public enum CleaningKind {
        REMOVE_PATH,
        COMMAND_ONLY
    }

    public class CleaningTarget : Object {
        public string id { get; construct set; }
        public string title { get; construct set; }
        public string description { get; construct set; }
        public string path { get; construct set; }
        public string command { get; construct set; }
        public string command_program { get; set; default = ""; }
        public string[] command_args { get; set; }
        public uint64 size_bytes { get; set; }
        public bool selected { get; set; default = true; }
        public CleaningKind kind { get; construct set; }
        public string icon_name { get; construct set; }

        // Same category, one collapsed row. Empty category means "leave it alone".
        public string category { get; set; default = ""; }

        // Zero bytes can still be real cleanup. Empty folders exist just to be annoying.
        public bool can_clean { get; construct set; }

        public CleaningTarget.remove_path (
            string id,
            string title,
            string description,
            string path,
            uint64 size_bytes,
            bool selected_by_default = true,
            string icon_name = "folder-symbolic",
            bool? can_clean = null
        ) {
            bool resolved_can_clean = can_clean ?? (size_bytes > 0);

            Object (
                id: id,
                title: title,
                description: description,
                path: path,
                command: "",
                kind: CleaningKind.REMOVE_PATH,
                size_bytes: size_bytes,
                selected: resolved_can_clean && selected_by_default,
                icon_name: icon_name,
                can_clean: resolved_can_clean
            );
        }

        public CleaningTarget.command_only (
            string id,
            string title,
            string description,
            string command_program,
            string[] command_args,
            string icon_name = "package-x-generic-symbolic"
        ) {
            string[] display_parts = { command_program };
            foreach (string arg in command_args) {
                display_parts += arg;
            }

            Object (
                id: id,
                title: title,
                description: description,
                path: "",
                command: string.joinv (" ", display_parts),
                kind: CleaningKind.COMMAND_ONLY,
                size_bytes: 0,
                selected: false,
                icon_name: icon_name,
                can_clean: true
            );

            this.command_program = command_program;
            this.command_args = command_args;
        }
    }
}
