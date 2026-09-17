using Curl;

namespace Kindlerss.Net {
    /*
     * Errors that can be raised while fetching a remote resource.
     */
    public errordomain FetchError {
        INIT_FAILED,
        REQUEST_FAILED
    }

    /*
     * Simple HTTP fetcher built on top of the libcurl FFI binding.
     *
     * This namespace demonstrates how Vala code uses the low-level Curl
     * namespace defined in src/ffi/libcurl.vapi. For convenience it uses the
     * high-level kindlerss_curl_fetch() helper implemented in curl_shim.c,
     * which handles the libcurl write callback in plain C.
     */
    namespace Fetcher {
        public string fetch (string url) throws FetchError {
            int rc = Curl.global_init (Curl.GLOBAL_DEFAULT);
            if (rc != Curl.OK) {
                throw new FetchError.INIT_FAILED ("curl_global_init failed");
            }

            string result = "";
            try {
                string? body = Curl.curl_fetch (url, null);
                if (body == null) {
                    throw new FetchError.REQUEST_FAILED ("curl fetch failed");
                }
                result = body;
            } finally {
                Curl.global_cleanup ();
            }

            return result;
        }
    }
}
