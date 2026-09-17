/*
 * Compatibility shims for the Kindle sysroot.
 *
 * The sysroot ships a trimmed set of GLib headers (an old ~2.29-era set):
 * some macros that valac-generated C relies on are not declared, and the
 * equally old runtime library does not export newer functions, so only
 * header-level shims that introduce no new symbol dependencies are added
 * here. On the host the full GLib headers are present and this file is a
 * no-op. Force-included into all C sources via -include (see meson.build).
 */
#pragma once

#include <glib.h>
#include <glib-object.h>

/* glib-autocleanups.h is missing from the trimmed headers. valac emits
 * this macro for every GType it defines; generated code never uses
 * g_autoptr itself, so an empty definition is sufficient. */
#ifndef G_DEFINE_AUTOPTR_CLEANUP_FUNC
#define G_DEFINE_AUTOPTR_CLEANUP_FUNC(TypeName, func)
#endif

/* Not present in the old gmacros.h; only used as a code-gen hint. */
#ifndef G_GNUC_NO_INLINE
#define G_GNUC_NO_INLINE
#endif
