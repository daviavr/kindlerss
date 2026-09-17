using Gtk;
using Kindlerss.Store;

namespace Kindlerss.Ui {

    /*
     * Reusable row widget that displays one RSS feed item (article).
     *
     * Purely presentational: it handles no input. Gesture handling lives in
     * ArticleList, because a child that consumes button presses would break
     * swipe detection on the list.
     *
     * Fonts and shared metrics come from the global RC theme loaded by
     * MainWindow; this widget only assigns the style names
     * "kindlerss-article-title" and "kindlerss-article-subtitle". Padding
     * is scaled via the factor MainWindow derived from the screen width.
     */
    public class FeedItem : VBox {

        public Article article;

        public FeedItem (Article article, double scaling) {
            this.article = article;

            spacing = sc (scaling, 2);
            border_width = (uint) sc (scaling, 6);

            var title_label = new Label (article.title);
            title_label.name = "kindlerss-article-title";
            title_label.xalign = 0f;
            title_label.set_line_wrap (true);
            pack_start (title_label, false, false, 0);

            var subtitle = new Label ("%s - %s".printf (article.feed_name, article.published));
            subtitle.name = "kindlerss-article-subtitle";
            subtitle.xalign = 0f;
            pack_start (subtitle, false, false, 0);

            pack_start (new HSeparator (), false, false, 0);
        }

        private static int sc (double scaling, int pixels) {
            return (int) (pixels * scaling);
        }
    }
}
