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

        public ArticleList article_list;

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

        /*
         * The main screen is deliberately minimal: a header and a reserved
         * space that is filled entirely by the ArticleList component. All
         * content logic (fetching, paging, gestures) lives in that
         * component; this window only wires the article source.
         */
        private Widget build_content () {
            var box = new VBox (false, 0);
            box.border_width = (uint) sc (12);

            var header = new Label ("kindlerss");
            header.name = "kindlerss-header";
            header.xalign = 0f;
            box.pack_start (header, false, false, (uint) sc (4));

            box.pack_start (new HSeparator (), false, false, (uint) sc (4));

            article_list = new ArticleList (scaling);
            article_list.source = Data.MockFeed.fetch_articles;
            article_list.article_activated.connect ((article) => {
                debug ("article tapped: %s (%s)", article.title, article.url);
            });
            article_list.reload ();
            box.pack_start (article_list, true, true, 0);

            return box;
        }
    }
}