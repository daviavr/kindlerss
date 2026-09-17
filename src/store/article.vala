namespace Kindlerss.Store {

    /*
     * One RSS/Atom article (a "feed item"). Plain data object: the FreshRSS
     * client and the RSS/Atom fallback parser will both produce these, so
     * the rest of the app never cares where an article came from.
     *
     * NOTE: public fields only, no properties. Private instance data makes
     * valac emit g_type_add_instance_private(), which the Kindle's old
     * libgobject does not export (see meson.build).
     */
    public class Article {
        public string title;
        public string feed_name;
        /* Display-ready string for now ("2h ago"); will become a real
         * timestamp once the FreshRSS client lands. */
        public string published;
        public string url;
        public bool is_read;

        public Article (string title, string feed_name, string published, string url = "") {
            this.title = title;
            this.feed_name = feed_name;
            this.published = published;
            this.url = url;
            this.is_read = false;
        }
    }
}
