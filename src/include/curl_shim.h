/*
 * Header for the libcurl C shim used by the Vala FFI binding.
 *
 * The Vala compiler includes this header in every generated C file that uses
 * the Curl namespace, so the prototypes for our helper functions are visible
 * during C compilation.
 */

#ifndef CURL_SHIM_H
#define CURL_SHIM_H

#include <curl/curl.h>
#include <stddef.h>

int kindlerss_curl_setopt_string(CURL *curl, CURLoption option, const char *value);
int kindlerss_curl_setopt_long(CURL *curl, CURLoption option, long value);
int kindlerss_curl_setopt_pointer(CURL *curl, CURLoption option, void *value);

char *kindlerss_curl_fetch(const char *url, size_t *out_len);

#endif /* CURL_SHIM_H */
