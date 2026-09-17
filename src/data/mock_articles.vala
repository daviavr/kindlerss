using Kindlerss.Store;

namespace Kindlerss.Data {

    /*
     * Placeholder article data used until the FreshRSS client lands.
     * fetch_articles() returns the same shape the real client will return,
     * so swapping the source is a one-line change at the call site.
     */
    public class MockFeed {

        public static List<Article> fetch_articles () {
            List<Article> articles = new List<Article> ();

            articles.append (new Article (
                                          "Example headline: the quick brown fox jumps over the lazy dog",
                                          "Example Feed", "2h ago"));
            articles.append (new Article (
                                          "A longer article title that should wrap onto a second line on narrow screens",
                                          "Example Feed", "3h ago"));
            articles.append (new Article (
                                          "Kindle modding community releases new jailbreak",
                                          "KindleModding", "5h ago"));
            articles.append (new Article (
                                          "E-ink displays: why partial refresh matters",
                                          "E-Ink News", "yesterday"));
            articles.append (new Article (
                                          "Cross-compiling GTK2 apps for ARM",
                                          "Embedded Weekly", "yesterday"));
            articles.append (new Article (
                                          "Understanding the AwesomeWM title format",
                                          "KindleModding", "yesterday"));
            articles.append (new Article (
                                          "FreshRSS sync protocol explained",
                                          "RSS Planet", "2 days ago"));
            articles.append (new Article (
                                          "SQLite as an offline article cache",
                                          "SQLite Blog", "2 days ago"));
            articles.append (new Article (
                                          "Vala for embedded Linux development",
                                          "Vala News", "3 days ago"));
            articles.append (new Article (
                                          "Designing touch UI for e-ink",
                                          "E-Ink News", "3 days ago"));

            return (owned) articles;
        }
    }
}