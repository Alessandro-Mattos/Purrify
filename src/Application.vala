/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 Alessandro Mattos
 */

namespace Purrify {
    [CCode (cname = "LOCALEDIR")]
    extern const string LOCALE_DIR;

    public class Application : Gtk.Application {
        public Application () {
            Object (
                application_id: "io.github.alessandro_mattos.Purrify",
                flags: ApplicationFlags.FLAGS_NONE
            );
        }

        protected override void activate () {
            var window = this.active_window as MainWindow;

            if (window == null) {
                window = new MainWindow (this);
            }

            window.present ();
        }

        public static int main (string[] args) {
            Intl.setlocale (LocaleCategory.ALL, "");
            Intl.bindtextdomain ("purrify", LOCALE_DIR);
            Intl.bind_textdomain_codeset ("purrify", "UTF-8");
            Intl.textdomain ("purrify");

            var app = new Application ();
            return app.run (args);
        }
    }
}
