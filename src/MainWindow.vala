/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 Alessandro Mattos
 */

using Gee;

namespace Purrify {
    public class MainWindow : Gtk.ApplicationWindow {
        private const string DONATION_URL = "https://donate.stripe.com/cNicN42EFbHy54Y0P1frW00";

        private delegate void ToggleCallback ();

        // Group rows start cheap and stay cheap. A messy Downloads folder should
        // not turn rendering into soup.
        private class LiveGroup {
            public ArrayList<CleaningTarget> members = new ArrayList<CleaningTarget> ();
            public ArrayList<Gtk.CheckButton> child_checks = new ArrayList<Gtk.CheckButton> ();
            public Gtk.ListBoxRow row;
            public Gtk.Label description_label;
            public Gtk.Label size_label;
            public Gtk.CheckButton master_check;
            public Gtk.Box children_box;
            public bool suppress_master_toggle = false;
        }

        private Scanner scanner;
        private Cleaner cleaner;
        private Stats stats;
        private Preferences preferences;
        private ScanOptions scan_options;
        private ArrayList<CleaningTarget> targets;

        // Categories are grouped while the scan is still running.
        private HashMap<string, LiveGroup> live_groups;

        private Gtk.ListBox list_box;
        private Gtk.Label hero_number_label;
        private Gtk.Label hero_caption_label;
        private Gtk.Label status_label;
        private Gtk.Label total_freed_label;
        private Gtk.Button scan_button;
        private Gtk.Button clean_button;
        private Gtk.Spinner scan_spinner;
        private Gtk.CheckButton core_check;
        private Gtk.CheckButton flatpak_check;
        private Gtk.CheckButton downloads_check;
        private Gtk.CheckButton duplicates_check;
        private Gtk.CheckButton developer_tools_check;
        private uint64 last_clean_estimated_bytes = 0;
        private int last_clean_selected_count = 0;

        public MainWindow (Gtk.Application app) {
            Object (
                application: app,
                title: "Purrify",
                default_width: 760,
                default_height: 560
            );

            scanner = new Scanner ();
            cleaner = new Cleaner ();
            stats = new Stats ();
            preferences = new Preferences ();
            scan_options = preferences.load_scan_options ();
            targets = new ArrayList<CleaningTarget> ();
            live_groups = new HashMap<string, LiveGroup> ();

            build_ui ();
            // No auto-scan. The user should be the one starting the rummage.
        }

        private void build_ui () {
            var header = new Gtk.HeaderBar ();

            var title_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            var title = new Gtk.Label ("Purrify");
            title.add_css_class ("title");
            var subtitle = new Gtk.Label (_("A calm, safe cleaner"));
            subtitle.add_css_class ("subtitle");
            title_box.append (title);
            title_box.append (subtitle);
            header.set_title_widget (title_box);

            scan_spinner = new Gtk.Spinner ();
            scan_spinner.visible = false;
            header.pack_end (scan_spinner);

            var donation_button = new Gtk.Button.with_label (_("🐾 Feed the Cat"));
            donation_button.tooltip_text = _("Support Purrify");
            donation_button.add_css_class ("flat");
            donation_button.clicked.connect (() => open_donation_link ());
            header.pack_end (donation_button);

            scan_button = new Gtk.Button.with_label (_("Scan"));
            scan_button.clicked.connect (() => scan_targets ());
            header.pack_end (scan_button);

            clean_button = new Gtk.Button.with_label (_("Clean Selected"));
            clean_button.add_css_class ("suggested-action");
            clean_button.sensitive = false;
            clean_button.clicked.connect (() => clean_selected_targets ());
            header.pack_end (clean_button);

            set_titlebar (header);

            var root = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            set_child (root);

            var intro = new Gtk.Box (Gtk.Orientation.VERTICAL, 4);
            intro.margin_top = 24;
            intro.margin_bottom = 16;
            intro.margin_start = 24;
            intro.margin_end = 24;

            hero_number_label = new Gtk.Label (_("Ready"));
            hero_number_label.halign = Gtk.Align.START;
            hero_number_label.add_css_class ("title-1");
            hero_number_label.add_css_class ("numeric");
            hero_number_label.add_css_class (Granite.STYLE_CLASS_ACCENT);
            intro.append (hero_number_label);

            hero_caption_label = new Gtk.Label (_("Click Scan to look for safe things to clean."));
            hero_caption_label.halign = Gtk.Align.START;
            hero_caption_label.wrap = true;
            hero_caption_label.add_css_class ("dim-label");
            intro.append (hero_caption_label);

            root.append (intro);
            root.append (build_scan_options_box ());

            var scrolled = new Gtk.ScrolledWindow ();
            scrolled.vexpand = true;
            scrolled.margin_start = 24;
            scrolled.margin_end = 24;
            scrolled.margin_bottom = 12;

            list_box = new Gtk.ListBox ();
            list_box.add_css_class ("boxed-list");
            scrolled.set_child (list_box);
            root.append (scrolled);

            status_label = new Gtk.Label ("");
            status_label.wrap = true;
            status_label.halign = Gtk.Align.START;
            status_label.margin_start = 24;
            status_label.margin_end = 24;
            status_label.margin_bottom = 18;
            status_label.add_css_class ("caption");
            status_label.add_css_class ("dim-label");
            root.append (status_label);

            total_freed_label = new Gtk.Label ("");
            total_freed_label.wrap = true;
            total_freed_label.halign = Gtk.Align.START;
            total_freed_label.margin_start = 24;
            total_freed_label.margin_end = 24;
            total_freed_label.margin_bottom = 18;
            total_freed_label.add_css_class ("caption");
            total_freed_label.add_css_class ("dim-label");
            root.append (total_freed_label);

            refresh_total_freed_label ();
        }

        private void open_donation_link () {
            Gtk.show_uri (this, DONATION_URL, Gdk.CURRENT_TIME);
        }

        private Gtk.Widget build_scan_options_box () {
            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 8);
            box.margin_start = 24;
            box.margin_end = 24;
            box.margin_bottom = 12;

            var label = new Gtk.Label (_("Scan options"));
            label.halign = Gtk.Align.START;
            label.add_css_class ("heading");
            box.append (label);

            var checks = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            checks.hexpand = true;

            core_check = new Gtk.CheckButton.with_label (_("Caches & Trash"));
            core_check.active = scan_options.include_core;
            core_check.toggled.connect (() => {
                scan_options.include_core = core_check.active;
                save_scan_options ();
            });
            checks.append (core_check);

            flatpak_check = new Gtk.CheckButton.with_label (_("Flatpak"));
            flatpak_check.active = scan_options.include_flatpak;
            flatpak_check.toggled.connect (() => {
                scan_options.include_flatpak = flatpak_check.active;
                save_scan_options ();
            });
            checks.append (flatpak_check);

            downloads_check = new Gtk.CheckButton.with_label (_("Downloads"));
            downloads_check.active = scan_options.include_downloads;
            downloads_check.toggled.connect (() => {
                scan_options.include_downloads = downloads_check.active;
                duplicates_check.sensitive = downloads_check.active;
                save_scan_options ();
            });
            checks.append (downloads_check);

            duplicates_check = new Gtk.CheckButton.with_label (_("Duplicate review (slower)"));
            duplicates_check.active = scan_options.include_duplicates;
            duplicates_check.sensitive = scan_options.include_downloads;
            duplicates_check.toggled.connect (() => {
                scan_options.include_duplicates = duplicates_check.active;
                save_scan_options ();
            });
            checks.append (duplicates_check);

            developer_tools_check = new Gtk.CheckButton.with_label (_("Developer tools"));
            developer_tools_check.active = scan_options.include_developer_tools;
            developer_tools_check.toggled.connect (() => {
                scan_options.include_developer_tools = developer_tools_check.active;
                save_scan_options ();
            });
            checks.append (developer_tools_check);

            box.append (checks);

            var hint = new Gtk.Label (_("Downloads and duplicate review can take longer on large folders. Your scan choices are remembered locally."));
            hint.halign = Gtk.Align.START;
            hint.wrap = true;
            hint.add_css_class ("caption");
            hint.add_css_class ("dim-label");
            box.append (hint);

            return box;
        }

        private void save_scan_options () {
            preferences.save_scan_options (scan_options);
        }

        private void scan_targets (bool announce = true) {
            scan_button.sensitive = false;
            clean_button.sensitive = false;
            list_box.sensitive = false;
            set_scan_option_controls_sensitive (false);
            scan_spinner.visible = true;
            scan_spinner.start ();

            Gtk.Widget? child;
            while ((child = list_box.get_first_child ()) != null) {
                list_box.remove (child);
            }

            targets = new ArrayList<CleaningTarget> ();
            live_groups = new HashMap<string, LiveGroup> ();

            if (announce) {
                update_summary ();
                hero_caption_label.label = _("Looking for safe things to clean…");
                status_label.label = "";
            }

            // The scanner can find junk faster than GTK can draw rows. Cute bug, ugly
            // window. Throttle it so each result is actually rendered before the next one.
            var render_mutex = Mutex ();
            var render_cond = Cond ();

            new Thread<void*> ("purrify-scanner", () => {
                scanner.scan (scan_options, (target) => {
                    bool rendered = false;

                    Idle.add (() => {
                        handle_found_target (target);

                        render_mutex.lock ();
                        rendered = true;
                        render_cond.signal ();
                        render_mutex.unlock ();

                        return false;
                    });

                    render_mutex.lock ();
                    while (!rendered) {
                        render_cond.wait (render_mutex);
                    }
                    render_mutex.unlock ();
                });

                Idle.add (() => {
                    scan_button.sensitive = true;
                    clean_button.sensitive = has_selected_cleanable_targets ();
                    list_box.sensitive = true;
                    set_scan_option_controls_sensitive (true);
                    scan_spinner.stop ();
                    scan_spinner.visible = false;

                    if (targets.size == 0 && announce) {
                        show_empty_state ();
                    }

                    return false;
                });

                return null;
            });
        }

        private bool has_selected_cleanable_targets () {
            foreach (var target in targets) {
                if (target.can_clean && target.selected) {
                    return true;
                }
            }

            return false;
        }

        private void set_scan_option_controls_sensitive (bool sensitive) {
            core_check.sensitive = sensitive;
            flatpak_check.sensitive = sensitive;
            downloads_check.sensitive = sensitive;
            duplicates_check.sensitive = sensitive && scan_options.include_downloads;
            developer_tools_check.sensitive = sensitive;
        }

        private void show_empty_state () {
            hero_number_label.label = _("All clean");
            hero_caption_label.label = _("Nothing safe to clean was found with the current scan options.");
            status_label.label = _("Try enabling Downloads, duplicate review, or Developer tools if you want a broader review.");
        }

        private void handle_found_target (CleaningTarget target) {
            targets.add (target);

            if (target.category == "") {
                var row = create_target_row (target);
                list_box.append (row);
                reveal_new_row (row);
                update_summary ();
                return;
            }

            bool is_new_category = !live_groups.has_key (target.category);

            if (is_new_category) {
                live_groups.set (target.category, new LiveGroup ());
            }

            var group = live_groups.get (target.category);
            group.members.add (target);

            if (group.members.size == 1) {
                var row = create_target_row (target);
                group.row = (Gtk.ListBoxRow) row;
                list_box.append (row);
                reveal_new_row (row);
            } else if (group.members.size == 2) {
                list_box.remove (group.row);
                var new_row = build_group_shell (target.category, group);
                list_box.append (new_row);
                group.row = (Gtk.ListBoxRow) new_row;
                reveal_new_row (new_row);
            } else {
                append_group_member_widget (group, target);
            }

            if (group.members.size >= 2) {
                update_group_header (group);
            }

            update_summary ();
        }

        private Gtk.Widget build_group_shell (string category, LiveGroup group) {
            var row = new Gtk.ListBoxRow ();
            row.activatable = false;
            row.selectable = false;

            var container = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

            var header_wrapper = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 14);
            header_wrapper.margin_top = 14;
            header_wrapper.margin_bottom = 14;
            header_wrapper.margin_start = 14;
            header_wrapper.margin_end = 14;

            var master_check = new Gtk.CheckButton ();
            master_check.valign = Gtk.Align.CENTER;
            header_wrapper.append (master_check);
            group.master_check = master_check;

            var icon = new Gtk.Image.from_icon_name (group.members[0].icon_name);
            icon.valign = Gtk.Align.CENTER;
            icon.icon_size = Gtk.IconSize.LARGE;
            icon.add_css_class ("dim-label");
            header_wrapper.append (icon);

            var labels = new Gtk.Box (Gtk.Orientation.VERTICAL, 4);
            labels.hexpand = true;

            var title_label = new Gtk.Label (category);
            title_label.halign = Gtk.Align.START;
            title_label.add_css_class ("heading");
            labels.append (title_label);

            var description_label = new Gtk.Label ("");
            description_label.halign = Gtk.Align.START;
            description_label.wrap = true;
            description_label.add_css_class ("dim-label");
            labels.append (description_label);
            group.description_label = description_label;

            header_wrapper.append (labels);

            var size_label = new Gtk.Label ("");
            size_label.valign = Gtk.Align.CENTER;
            size_label.add_css_class ("numeric");
            header_wrapper.append (size_label);
            group.size_label = size_label;

            var expand_button = new Gtk.ToggleButton ();
            expand_button.icon_name = "pan-end-symbolic";
            expand_button.valign = Gtk.Align.CENTER;
            expand_button.add_css_class ("flat");
            header_wrapper.append (expand_button);

            container.append (header_wrapper);

            var children_revealer = new Gtk.Revealer ();
            children_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
            children_revealer.reveal_child = false;

            var children_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 2);
            children_box.margin_start = 40;
            children_box.margin_bottom = 8;
            group.children_box = children_box;

            foreach (var member in group.members) {
                append_group_member_widget (group, member);
            }

            children_revealer.set_child (children_box);
            container.append (children_revealer);

            expand_button.toggled.connect (() => {
                children_revealer.reveal_child = expand_button.active;
                expand_button.icon_name = expand_button.active ? "pan-down-symbolic" : "pan-end-symbolic";
            });

            master_check.toggled.connect (() => {
                if (group.suppress_master_toggle) {
                    return;
                }

                bool new_state = master_check.active;
                master_check.inconsistent = false;

                for (int i = 0; i < group.members.size; i++) {
                    group.members[i].selected = new_state;
                    group.child_checks[i].active = new_state;
                }

                update_summary ();
            });

            refresh_master_state (group);

            var revealer = new Gtk.Revealer ();
            revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
            revealer.reveal_child = false;
            revealer.set_child (container);

            row.set_child (revealer);
            return row;
        }

        private void append_group_member_widget (LiveGroup group, CleaningTarget target) {
            var child_check = new Gtk.CheckButton ();
            group.child_checks.add (child_check);
            group.children_box.append (create_row_content (target, child_check, () => refresh_master_state (group)));
        }

        private void update_group_header (LiveGroup group) {
            group.description_label.label = ngettext (
                "%d item found. Expand to choose individually.",
                "%d items found. Expand to choose individually.",
                group.members.size
            ).printf (group.members.size);

            uint64 group_size = 0;
            foreach (var member in group.members) {
                group_size += member.size_bytes;
            }

            group.size_label.label = group_size > 0 ? FileUtils.format_bytes (group_size) : "";

            refresh_master_state (group);
        }

        private void refresh_master_state (LiveGroup group) {
            int selected_count = 0;

            foreach (var member in group.members) {
                if (member.selected) {
                    selected_count++;
                }
            }

            group.suppress_master_toggle = true;

            if (selected_count == 0) {
                group.master_check.inconsistent = false;
                group.master_check.active = false;
            } else if (selected_count == group.members.size) {
                group.master_check.inconsistent = false;
                group.master_check.active = true;
            } else {
                group.master_check.inconsistent = true;
            }

            group.suppress_master_toggle = false;
        }

        private void reveal_new_row (Gtk.Widget row) {
            var list_row = row as Gtk.ListBoxRow;
            var revealer = list_row != null ? list_row.get_child () as Gtk.Revealer : null;

            if (revealer == null) {
                return;
            }

            Idle.add (() => {
                revealer.reveal_child = true;
                return false;
            });
        }

        private Gtk.Widget create_row_content (
            CleaningTarget target,
            Gtk.CheckButton check,
            ToggleCallback? on_toggle
        ) {
            var wrapper = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 14);
            wrapper.margin_top = 14;
            wrapper.margin_bottom = 14;
            wrapper.margin_start = 14;
            wrapper.margin_end = 14;

            check.valign = Gtk.Align.CENTER;
            check.active = target.selected;
            check.sensitive = target.can_clean;
            check.toggled.connect (() => {
                target.selected = check.active;
                update_summary ();

                if (on_toggle != null) {
                    on_toggle ();
                }
            });
            wrapper.append (check);

            var icon = new Gtk.Image.from_icon_name (target.icon_name);
            icon.valign = Gtk.Align.CENTER;
            icon.icon_size = Gtk.IconSize.LARGE;
            icon.add_css_class ("dim-label");
            wrapper.append (icon);

            var labels = new Gtk.Box (Gtk.Orientation.VERTICAL, 4);
            labels.hexpand = true;
            labels.tooltip_text = target.kind == CleaningKind.COMMAND_ONLY ? target.command : target.path;

            var title = new Gtk.Label (target.title);
            title.halign = Gtk.Align.START;
            title.add_css_class ("heading");
            labels.append (title);

            var description = new Gtk.Label (target.description);
            description.halign = Gtk.Align.START;
            description.wrap = true;
            description.add_css_class ("dim-label");
            labels.append (description);

            wrapper.append (labels);

            if (target.kind == CleaningKind.REMOVE_PATH && target.size_bytes > 0) {
                var size = new Gtk.Label (FileUtils.format_bytes (target.size_bytes));
                size.valign = Gtk.Align.CENTER;
                size.add_css_class ("numeric");
                wrapper.append (size);
            }

            return wrapper;
        }

        private Gtk.Widget create_target_row (CleaningTarget target) {
            var row = new Gtk.ListBoxRow ();
            row.activatable = false;
            row.selectable = false;

            var content = create_row_content (target, new Gtk.CheckButton (), null);

            var revealer = new Gtk.Revealer ();
            revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
            revealer.reveal_child = false;
            revealer.set_child (content);

            row.set_child (revealer);
            return row;
        }

        private void update_summary () {
            uint64 total = 0;
            int selected_count = 0;

            foreach (var target in targets) {
                if (!target.selected) {
                    continue;
                }

                if (target.kind == CleaningKind.REMOVE_PATH) {
                    total += target.size_bytes;
                }

                selected_count++;
            }

            if (selected_count == 0) {
                hero_number_label.label = "0 B";
                hero_caption_label.label = _("Nothing selected yet. Everything found is listed below.");
            } else {
                hero_number_label.label = FileUtils.format_bytes (total);
                hero_caption_label.label = ngettext (
                    "%d item selected. Nothing is removed until you confirm.",
                    "%d items selected. Nothing is removed until you confirm.",
                    selected_count
                ).printf (selected_count);
            }

            clean_button.sensitive = selected_count > 0 && scan_button.sensitive;
        }

        private ArrayList<CleaningTarget> get_selected_targets () {
            var selected = new ArrayList<CleaningTarget> ();

            foreach (var target in targets) {
                if (target.selected && target.can_clean) {
                    selected.add (target);
                }
            }

            return selected;
        }

        private void clean_selected_targets () {
            var selected = get_selected_targets ();

            if (selected.size == 0) {
                status_label.label = _("Select at least one item to clean.");
                return;
            }

            uint64 total_bytes = 0;
            int command_count = 0;

            foreach (var target in selected) {
                if (target.kind == CleaningKind.REMOVE_PATH) {
                    total_bytes += target.size_bytes;
                } else {
                    command_count++;
                }
            }

            last_clean_estimated_bytes = total_bytes;
            last_clean_selected_count = selected.size;

            string secondary_text = command_count > 0
                ? ngettext (
                    "This will permanently remove about %s and run %d command on your system. This cannot be undone.",
                    "This will permanently remove about %s and run %d commands on your system. This cannot be undone.",
                    command_count
                ).printf (
                    FileUtils.format_bytes (total_bytes), command_count
                )
                : _("This will permanently remove about %s. This cannot be undone.").printf (
                    FileUtils.format_bytes (total_bytes)
                );
            secondary_text += "\n\n" + build_selected_category_summary (selected);

            var dialog = new Granite.MessageDialog.with_image_from_icon_name (
                ngettext (
                    "Delete %d item?",
                    "Delete %d items?",
                    selected.size
                ).printf (selected.size),
                secondary_text,
                "dialog-warning",
                Gtk.ButtonsType.NONE
            );
            dialog.transient_for = this;
            dialog.modal = true;

            dialog.add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
            var delete_button = dialog.add_button (_("Delete"), Gtk.ResponseType.ACCEPT);
            delete_button.add_css_class ("destructive-action");

            dialog.response.connect ((response_id) => {
                dialog.destroy ();

                if (response_id == Gtk.ResponseType.ACCEPT) {
                    perform_cleanup (selected);
                }
            });

            dialog.present ();
        }

        private string build_selected_category_summary (ArrayList<CleaningTarget> selected) {
            var counts = new HashMap<string, int> ();

            foreach (var target in selected) {
                string name = target.category != "" ? target.category : target.title;
                counts.set (name, counts.has_key (name) ? counts.get (name) + 1 : 1);
            }

            string summary = "";
            int shown = 0;

            foreach (string name in counts.keys) {
                if (shown >= 5) {
                    break;
                }

                int count = counts.get (name);
                string part = ngettext (
                    "%s (%d item)",
                    "%s (%d items)",
                    count
                ).printf (name, count);

                summary = summary == "" ? part : summary + ", " + part;
                shown++;
            }

            int remaining = counts.size - shown;
            if (remaining > 0) {
                summary += ", " + ngettext (
                    "%d more category",
                    "%d more categories",
                    remaining
                ).printf (remaining);
            }

            return _("Included: %s").printf (summary);
        }

        private void perform_cleanup (ArrayList<CleaningTarget> selected) {
            clean_button.sensitive = false;
            scan_button.sensitive = false;
            list_box.sensitive = false;
            set_scan_option_controls_sensitive (false);
            hero_caption_label.label = _("Cleaning selected items…");

            var paths = new ArrayList<CleaningTarget> ();
            var commands = new ArrayList<CleaningTarget> ();

            foreach (var target in selected) {
                if (target.kind == CleaningKind.REMOVE_PATH) {
                    paths.add (target);
                } else {
                    commands.add (target);
                }
            }

            // Big deletes can freeze the main loop and make the desktop accuse us of
            // crimes. Do the work off-thread; bring back only the receipt.
            new Thread<void*> ("purrify-cleaner", () => {
                var result = cleaner.clean (paths);
                int failed_commands = 0;

                foreach (var target in commands) {
                    var command_result = cleaner.run_command (target);

                    if (!command_result.success) {
                        failed_commands++;
                        result.failure_messages.add (_("%s: %s").printf (target.title, command_result.error_message));
                        stderr.printf (_("Failed to run %s: %s\n"), target.command, command_result.error_message);
                    } else {
                        result.cleaned_commands++;
                    }
                }

                Idle.add (() => {
                    on_cleanup_finished (result, failed_commands);
                    return false;
                });

                return null;
            });
        }

        private void on_cleanup_finished (CleanupResult result, int failed_commands) {
            int failed_total = result.failed_count + failed_commands;
            stats.add_freed_bytes (result.cleaned_bytes);

            hero_number_label.label = FileUtils.format_bytes (result.cleaned_bytes);
            hero_caption_label.label = result.cleaned_count > 0 || result.cleaned_commands > 0
                ? _("Before: about %s selected. After: %s freed.").printf (
                    FileUtils.format_bytes (last_clean_estimated_bytes),
                    FileUtils.format_bytes (result.cleaned_bytes)
                )
                : _("Nothing was removed.");

            string failure_note = failed_total > 0
                ? " " + ngettext (
                    "%d item could not be removed.",
                    "%d items could not be removed.",
                    failed_total
                ).printf (failed_total)
                : "";

            if (result.cleaned_count > 0 || result.cleaned_commands > 0) {
                string action_summary = ngettext (
                    "%d item cleaned",
                    "%d items cleaned",
                    result.cleaned_count
                ).printf (result.cleaned_count);

                if (result.cleaned_commands > 0) {
                    action_summary += "; " + ngettext (
                        "%d command completed",
                        "%d commands completed",
                        result.cleaned_commands
                    ).printf (result.cleaned_commands);
                }

                status_label.label = _("%s.%s If it saved you some hassle, a good rating helps a lot.").printf (
                    action_summary,
                    failure_note
                );
            } else {
                status_label.label = _("Nothing to report.%s").printf (failure_note);
            }

            string details = build_failure_details (result);
            if (details != "") {
                status_label.label += " " + details;
            }

            refresh_total_freed_label ();
            scan_targets (false);
        }

        private string build_failure_details (CleanupResult result) {
            if (result.failure_messages.size == 0) {
                return "";
            }

            string details = _("Could not remove: ");
            int shown = 0;

            foreach (string message in result.failure_messages) {
                if (shown >= 3) {
                    break;
                }

                details += shown == 0 ? message : "; " + message;
                shown++;
            }

            int remaining = result.failure_messages.size - shown;
            if (remaining > 0) {
                details += "; " + ngettext (
                    "%d more failure",
                    "%d more failures",
                    remaining
                ).printf (remaining);
            }

            return details;
        }

        private void refresh_total_freed_label () {
            uint64 total = stats.get_total_freed_bytes ();

            total_freed_label.label = total == 0
                ? _("Nothing cleaned yet.")
                : _("%s freed since you installed Purrify.").printf (FileUtils.format_bytes (total));
        }
    }
}
