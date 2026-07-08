/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 Alessandro Mattos
 */

using Gee;

namespace Purrify {
    public delegate void BatchStateCallback (bool batching);
    public delegate void ChildSelectionApplier (int index, bool new_state);
    public delegate void SelectionBatchCallback ();

    public class GroupSelectionBatch : Object {
        public static void apply_master_toggle (
            ArrayList<CleaningTarget> members,
            bool new_state,
            BatchStateCallback set_batching,
            ChildSelectionApplier apply_child_state,
            SelectionBatchCallback refresh_master_state,
            SelectionBatchCallback update_summary
        ) {
            set_batching (true);

            for (int i = 0; i < members.size; i++) {
                members[i].selected = new_state;
                apply_child_state (i, new_state);
            }

            set_batching (false);
            refresh_master_state ();
            update_summary ();
        }
    }
}
