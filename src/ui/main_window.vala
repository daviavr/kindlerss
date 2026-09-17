using Gtk;

namespace Kindlerss.Ui {

    /*
     * Main application window.
     *
     * All pixel metrics are derived from the screen dimensions: values are
     * written for a 600px reference width (the original Kindle Touch) and
     * multiplied by a scaling factor at runtime. Font sizes stay in points
     * and are deliberately NOT scaled: the Kindle X server reports the real
     * panel DPI, so point sizes already render at the same physical size on
     * every model. Scaling fonts as well would double-scale them on the
     * 300 dpi devices.
     *
     * Host development: the real monitor size is used by default. Override
     * it to preview a specific Kindle model, e.g.
     *
     *   KINDLERSS_SCREEN_WIDTH=1072 KINDLERSS_SCREEN_HEIGHT=1448 ./builddir/kindlerss
     */
    public class MainWindow : Window {

        private const string APP_ID = "org.kindlerss.rssreader";
        private const double REFERENCE_WIDTH = 600.0;

        /* NOTE: a plain public field, not a property: any private instance
         * data (including automatic property backing fields) makes valac
         * emit g_type_add_instance_private(), which the Kindle's old
         * libgobject does not export (see meson.build). */
        public double scaling = 1.0;

        public MainWindow () {
            title = "L:A_N:application_PC:N_ID:" + APP_ID;
            border_width = 0;
            destroy.connect (Gtk.main_quit);

            int width, height;
            detect_dimensions (out width, out height);
            scaling = width / REFERENCE_WIDTH;

            set_default_size (width, height);

            load_styles ();
            add (build_content ());
        }

        /* Scale a 600px-baseline pixel value to this device. */
        public int sc (int pixels) {
            return (int) (pixels * scaling);
        }

        private void detect_dimensions (out int width, out int height) {
            var screen = get_screen ();
            width = screen.get_width ();
            height = screen.get_height ();

            string? env_w = Environment.get_variable ("KINDLERSS_SCREEN_WIDTH");
            string? env_h = Environment.get_variable ("KINDLERSS_SCREEN_HEIGHT");
            if (env_w != null && int.parse (env_w) > 0)
                width = int.parse (env_w);
            if (env_h != null && int.parse (env_h) > 0)
                height = int.parse (env_h);
        }

        /*
         * GTK2 RC styles. Pixel values written as @N are multiplied by the
         * scaling factor before the style is parsed (technique borrowed
         * from the ranki Kindle app).
         */
        private void load_styles () {
            string rc = """
                style "kindlerss-base" {
                    font_name = "Amazon Ember Regular 10"
                    xthickness = @4
                    ythickness = @4
                    GtkScrollbar::slider-width = @10
                    GtkScrollbar::stepper-size = 0
                }
                widget_class "*" style "kindlerss-base"

                style "kindlerss-header" {
                    font_name = "Amazon Ember Bold 16"
                }
                widget "*.kindlerss-header" style "kindlerss-header"

                style "kindlerss-article-title" {
                    font_name = "Amazon Ember Bold 11"
                }
                widget "*.kindlerss-article-title" style "kindlerss-article-title"

                style "kindlerss-article-subtitle" {
                    font_name = "Amazon Ember Regular 9"
                }
                widget "*.kindlerss-article-subtitle" style "kindlerss-article-subtitle"
            """;

            try {
                var regex = new Regex ("@(\\d+)");
                string parsed = regex.replace_eval (rc, rc.length, 0, 0, (match, result) => {
                    int value = int.parse (match.fetch (1));
                    result.append (((int) (value * scaling)).to_string ());
                    return false;
                });
                rc_parse_string (parsed);
            } catch (RegexError e) {
                warning ("failed to scale styles: %s", e.message);
                rc_parse_string (rc.replace ("@", ""));
            }
        }

        private Widget build_content () {
            var box = new VBox (false, 0);
            box.border_width = (uint) sc (12);

            var header = new Label ("kindlerss");
            header.name = "kindlerss-header";
            header.xalign = 0f;
            box.pack_start (header, false, false, (uint) sc (4));

            box.pack_start (new HSeparator (), false, false, (uint) sc (4));

            var list = new VBox (false, 0);
            string[] titles = {
                "Example headline: the quick brown fox jumps over the lazy dog",
                "A longer article title that should wrap onto a second line on narrow screens",
                "Kindle modding community releases new jailbreak",
                "E-ink displays: why partial refresh matters",
                "Cross-compiling GTK2 apps for ARM",
                "Understanding the AwesomeWM title format",
                "FreshRSS sync protocol explained",
                "SQLite as an offline article cache",
                "Vala for embedded Linux development",
                "Designing touch UI for e-ink"
            };
            string[] subtitles = {
                "Example Feed - 2h ago",
                "Example Feed - 3h ago",
                "KindleModding - 5h ago",
                "E-Ink News - yesterday",
                "Embedded Weekly - yesterday",
                "KindleModding - yesterday",
                "RSS Planet - 2 days ago",
                "SQLite Blog - 2 days ago",
                "Vala News - 3 days ago",
                "E-Ink News - 3 days ago"
            };
            for (int i = 0; i < titles.length; i++)
                list.pack_start (build_article_row (titles[i], subtitles[i]), false, false, 0);

            var scrolled = new ScrolledWindow (null, null);
            scrolled.set_policy (PolicyType.NEVER, PolicyType.AUTOMATIC);
            scrolled.add_with_viewport (list);
            box.pack_start (scrolled, true, true, 0);

            box.pack_start (new HSeparator (), false, false, (uint) sc (4));

            var buttons = new HBox (true, sc (8));
            buttons.pack_start (new Button.with_label ("Refresh"));
            buttons.pack_start (new Button.with_label ("Settings"));
            box.pack_start (buttons, false, false, (uint) sc (4));

            return box;
        }

        private Widget build_article_row (string title_text, string subtitle_text) {
            var row = new VBox (false, sc (2));
            row.border_width = (uint) sc (4);

            var title_label = new Label (title_text);
            title_label.name = "kindlerss-article-title";
            title_label.xalign = 0f;
            title_label.set_line_wrap (true);
            row.pack_start (title_label, false, false, 0);

            var subtitle = new Label (subtitle_text);
            subtitle.name = "kindlerss-article-subtitle";
            subtitle.xalign = 0f;
            row.pack_start (subtitle, false, false, 0);

            var wrapper = new VBox (false, 0);
            wrapper.pack_start (row, false, false, 0);
            wrapper.pack_start (new HSeparator (), false, false, 0);
            return wrapper;
        }
    }
}