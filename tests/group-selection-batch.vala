/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 Alessandro Mattos
 */

using Gee;

namespace Purrify.Tests {
    private void test_apply_master_toggle_batches_follow_up_work () {
        var members = new ArrayList<CleaningTarget> ();

        for (int i = 0; i < 3; i++) {
            members.add (new CleaningTarget.remove_path (
                "duplicate-%d".printf (i),
                "Duplicate %d".printf (i),
                "test",
                "/tmp/duplicate-%d".printf (i),
                1024,
                false
            ));
        }

        int child_updates = 0;
        int refresh_calls = 0;
        int summary_updates = 0;
        var batching_states = new ArrayList<bool?> ();

        GroupSelectionBatch.apply_master_toggle (
            members,
            true,
            (batching) => {
                batching_states.add (batching);
            },
            (index, new_state) => {
                child_updates++;
            },
            () => {
                refresh_calls++;
            },
            () => {
                summary_updates++;
            }
        );

        assert (batching_states.size == 2);
        assert (batching_states[0] == true);
        assert (batching_states[1] == false);
        assert (child_updates == 3);
        assert (refresh_calls == 1);
        assert (summary_updates == 1);

        foreach (var member in members) {
            assert (member.selected);
        }
    }

    public static int main (string[] args) {
        test_apply_master_toggle_batches_follow_up_work ();
        return 0;
    }
}
