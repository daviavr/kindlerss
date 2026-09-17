/*
 * C shim for the libcurl FFI binding.
 *
 * libcurl uses variadic macros for curl_easy_setopt(), which Vala cannot call
 * directly. We provide type-safe wrappers and a high-level fetch helper that
 * captures the response body into a dynamically grown buffer.
 */

#include "curl_shim.h"
#include <glib.h>
#include <string.h>

typedef struct {
    gchar *data;
    gsize size;
} KindlerssBuffer;

static size_t kindlerss_write_callback(void *contents, size_t size, size_t nmemb, void *userp) {
    size_t total = size * nmemb;
    KindlerssBuffer *buf = (KindlerssBuffer *) userp;
    gchar *ptr = g_realloc(buf->data, buf->size + total + 1);

    if (ptr == NULL) {
        return 0;
    }

    memcpy(ptr + buf->size, contents, total);
    buf->data = ptr;
    buf->size += total;
    buf->data[buf->size] = '\0';

    return total;
}

int kindlerss_curl_setopt_string(CURL *curl, CURLoption option, const char *value) {
    return curl_easy_setopt(curl, option, value);
}

int kindlerss_curl_setopt_long(CURL *curl, CURLoption option, long value) {
    return curl_easy_setopt(curl, option, value);
}

int kindlerss_curl_setopt_pointer(CURL *curl, CURLoption option, void *value) {
    return curl_easy_setopt(curl, option, value);
}

char *kindlerss_curl_fetch(const char *url, size_t *out_len) {
    CURL *curl;
    CURLcode res;
    KindlerssBuffer buf = { NULL, 0 };

    curl = curl_easy_init();
    if (curl == NULL) {
        return NULL;
    }

    curl_easy_setopt(curl, CURLOPT_URL, url);
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, kindlerss_write_callback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *) &buf);

    res = curl_easy_perform(curl);
    curl_easy_cleanup(curl);

    if (res != CURLE_OK) {
        g_free(buf.data);
        return NULL;
    }

    if (out_len != NULL) {
        *out_len = buf.size;
    }

    return buf.data;
}
