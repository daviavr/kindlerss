using Gtk;
using Kindlerss.Store;

namespace Kindlerss.Ui {

    /*
     * Reusable row widget that displays one RSS feed item (article).
     *
     * Fonts and shared metrics come from the global RC theme loaded by
     * MainWindow; this widget only assigns the style names
     * "kindlerss-article-title" and "kindlerss-article-subtitle". Padding
     * is scaled via the factor MainWindow derived from the screen width.
     */
    public class FeedItem : EventBox {

        /* Emitted when the row is tapped/clicked. */
        public signal void activated (Article article);

        public FeedItem (Article article, double scaling) {
            var row = new VBox (false, sc (scaling, 2));
            row.border_width = (uint) sc (scaling, 6);

            var title_label = new Label (article.title);
            title_label.name = "kindlerss-article-title";
            title_label.xalign = 0f;
            title_label.set_line_wrap (true);
            row.pack_start (title_label, false, false, 0);

            var subtitle = new Label ("%s - %s".printf (article.feed_name, article.published));
            subtitle.name = "kindlerss-article-subtitle";
            subtitle.xalign = 0f;
            row.pack_start (subtitle, false, false, 0);

            var content = new VBox (false, 0);
            content.pack_start (row, false, false, 0);
            content.pack_start (new HSeparator (), false, false, 0);
            add (content);

            button_press_event.connect ((event) => {
                if (event.button == 1) {
                    activated (article);
                    return true;
                }
                return false;
            });
        }

        private static int sc (double scaling, int pixels) {
            return (int) (pixels * scaling);
        }
    }
}
