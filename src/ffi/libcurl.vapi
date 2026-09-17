/*
 * Minimal libcurl FFI binding for kindlerss.
 *
 * This VAPI maps a small subset of the libcurl C API into Vala so we can
 * initialize handles, set options, perform requests, and retrieve the response
 * body from Vala code.
 *
 * Because curl_easy_setopt() is a variadic C function, we expose type-safe
 * helper functions implemented in curl_shim.c instead of calling the varargs
 * version directly from Vala.
 */

[CCode (cheader_filename = "curl_shim.h")]
namespace Curl {
    /*
     * Global initialization. Must be called once before any other curl
     * functions, and must be paired with global_cleanup().
     */
    [CCode (cname = "curl_global_init")]
    public static int global_init (long flags);

    [CCode (cname = "curl_global_cleanup")]
    public static void global_cleanup ();

    /*
     * Opaque CURL easy handle. Marked [Compact] so Vala treats it as a plain
     * C pointer that is destroyed with curl_easy_cleanup().
     */
    [CCode (cname = "CURL", has_type_id = false, destroy_function = "curl_easy_cleanup")]
    [Compact]
    public class Easy {
        [CCode (cname = "curl_easy_init")]
        public Easy ();
    }

    [CCode (cname = "curl_easy_perform")]
    public static int easy_perform (Easy curl);

    [CCode (cname = "curl_easy_strerror")]
    public static string easy_strerror (int code);

    /* Type-safe curl_easy_setopt() helpers implemented in curl_shim.c */
    [CCode (cname = "kindlerss_curl_setopt_string")]
    public static int easy_setopt_string (Easy curl, int option, string value);

    [CCode (cname = "kindlerss_curl_setopt_long")]
    public static int easy_setopt_long (Easy curl, int option, long value);

    [CCode (cname = "kindlerss_curl_setopt_pointer")]
    public static int easy_setopt_pointer (Easy curl, int option, void* value);

    /*
     * High-level helper: perform a GET request for url and return the response
     * body as a NUL-terminated string. The returned string is owned by the
     * caller. On error, null is returned.
     */
    [CCode (cname = "kindlerss_curl_fetch")]
    public static string ? curl_fetch (string url, out size_t out_len);

    /* Option constants used by curl_easy_setopt() */
    [CCode (cname = "CURLOPT_URL")]
    public const int OPTION_URL;

    [CCode (cname = "CURLOPT_FOLLOWLOCATION")]
    public const int OPTION_FOLLOWLOCATION;

    [CCode (cname = "CURLOPT_USERAGENT")]
    public const int OPTION_USERAGENT;

    [CCode (cname = "CURLOPT_WRITEFUNCTION")]
    public const int OPTION_WRITEFUNCTION;

    [CCode (cname = "CURLOPT_WRITEDATA")]
    public const int OPTION_WRITEDATA;

    /* Global init flags */
    [CCode (cname = "CURL_GLOBAL_DEFAULT")]
    public const long GLOBAL_DEFAULT;

    /* Return codes */
    [CCode (cname = "CURLE_OK")]
    public const int OK;
}