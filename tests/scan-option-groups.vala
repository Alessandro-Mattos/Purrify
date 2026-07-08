/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 Alessandro Mattos
 */

namespace Purrify.Tests {
    private void test_disabling_folders_also_disables_duplicate_review () {
        var options = new ScanOptions ();
        options.include_folders = true;
        options.include_duplicates = true;

        ScanOptionGroups.set_folders_enabled (options, false);

        assert (!options.include_folders);
        assert (!options.include_duplicates);
    }

    private void test_enabling_folders_keeps_duplicate_review_off_until_requested () {
        var options = new ScanOptions ();
        options.include_folders = false;
        options.include_duplicates = false;

        ScanOptionGroups.set_folders_enabled (options, true);

        assert (options.include_folders);
        assert (!options.include_duplicates);
        assert (ScanOptionGroups.duplicate_review_sensitive (options));
    }

    private void test_legacy_options_migrate_to_new_groups () {
        var options = ScanOptionGroups.from_legacy (
            true,
            false,
            false,
            true,
            false
        );

        assert (options.include_apps_cache);
        assert (options.include_folders);
        assert (options.include_duplicates);
    }

    public static int main (string[] args) {
        test_disabling_folders_also_disables_duplicate_review ();
        test_enabling_folders_keeps_duplicate_review_off_until_requested ();
        test_legacy_options_migrate_to_new_groups ();
        return 0;
    }
}
