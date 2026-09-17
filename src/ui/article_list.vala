using Gtk;
using Kindlerss.Store;

namespace Kindlerss.Ui {

    /* Provides the articles to display. The mock data source and the future
     * FreshRSS client both plug in through this seam. */
    public delegate List<Article> ArticleSource ();

    /*
     * Paginated list of articles, sized to fill its allocation without any
     * scrolling (scrollbars are a poor fit for e-ink).
     *
     * - The number of rows per page is derived from the allocated height.
     * - A horizontal swipe turns the page: left for next, right for
     *   previous.
     * - A tap (press + release without a swipe) activates the row under the
     *   finger.
     *
     * It is an EventBox so that swipes also register on the empty space
     * below the last row.
     *
     * NOTE: public fields only - private instance data is off-limits on the
     * Kindle's old libgobject (see meson.build).
     */
    public class ArticleList : EventBox {

        /* Emitted when a row is tapped. */
        public signal void article_activated (Article article);

        public ArticleSource? source = null;
        public double scaling;

        public List<Article>? articles = null;
        public int page = 0;
        public int per_page = 0;

        public VBox rows;
        public Label page_label;

        public double press_x = 0.0;

        public ArticleList (double scaling) {
            this.scaling = scaling;

            var box = new VBox (false, 0);

            rows = new VBox (false, 0);
            box.pack_start (rows, true, true, 0);

            page_label = new Label ("");
            page_label.name = "kindlerss-article-subtitle";
            box.pack_start (page_label, false, false, (uint) sc (4));

            add (box);

            button_press_event.connect (on_button_press);
            button_release_event.connect (on_button_release);
            size_allocate.connect (on_size_allocate);
        }

        private int sc (int pixels) {
            return (int) (pixels * scaling);
        }

        /* (Re)load articles from the source and go back to the first page. */
        public void reload () {
            if (source == null)
                return;
            articles = source ();
            page = 0;
            render ();
        }

        public void next_page () {
            if (articles == null)
                return;
            if ((page + 1) * per_page < (int) articles.length ()) {
                page++;
                render ();
            }
        }

        public void previous_page () {
            if (page > 0) {
                page--;
                render ();
            }
        }

        private void render () {
            foreach (var child in rows.get_children ())
                rows.remove (child);

            if (articles == null || per_page <= 0)
                return;

            int start = page * per_page;
            int i = 0;
            foreach (var article in articles) {
                if (i >= start && i < start + per_page)
                    rows.pack_start (new FeedItem (article, scaling), false, false, 0);
                i++;
            }
            rows.show_all ();

            int total_pages = ((int) articles.length () + per_page - 1) / per_page;
            page_label.set_text ("%d / %d".printf (page + 1, total_pages));
        }

        private void on_size_allocate (Gdk.Rectangle allocation) {
            /* Estimate a row height generously: if rows turn out shorter we
             * merely show fewer of them, while an underestimate would clip
             * content with no scrollbar to reach it. */
            int new_per_page = int.max (1, (allocation.height - sc (28)) / sc (64));
            if (new_per_page != per_page) {
                per_page = new_per_page;
                render ();
            }
        }

        private bool on_button_press (Gdk.EventButton event) {
            if (event.button == 1) {
                press_x = event.x;
                return true;
            }
            return false;
        }

        private bool on_button_release (Gdk.EventButton event) {
            if (event.button != 1)
                return false;

            double dx = event.x - press_x;
            int threshold = sc (48);

            if (dx <= -threshold) {
                next_page ();
            } else if (dx >= threshold) {
                previous_page ();
            } else {
                /* Tap: activate the row under the finger. */
                foreach (var child in rows.get_children ()) {
                    if (event.y >= child.allocation.y &&
                        event.y < child.allocation.y + child.allocation.height) {
                        article_activated (((FeedItem) child).article);
                        break;
                    }
                }
            }
            return true;
        }
    }
}
