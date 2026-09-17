project('kindlerss', ['vala', 'c'], version: 'v1.0.0', meson_version: '>=1.1')

# Compiler used for C sources (needed for find_library).
cc = meson.get_compiler('c')

# The Kindle sysroot glib is old (~2.29, despite what its .pc files claim),
# so generate C that only needs ancient GLib APIs. NOTE: valac still emits
# g_type_add_instance_private() (absent from the Kindle libgobject) for any
# class with private instance data - use public fields instead of private
# fields or automatic properties in GObject classes.
add_project_arguments('--target-glib=2.32', language: 'vala')

# Missing-macro shims for the trimmed Kindle sysroot headers (see the
# header itself; a no-op on the host).
add_project_arguments('-include', 'glib_compat.h', language: 'c')

# Define dependencies we want
gtk_dep = dependency('gtk+-2.0')
glib_dep = dependency('glib-2.0')

# libcurl is used through a custom Vala FFI binding (src/ffi/libcurl.vapi).
# We do not use dependency('libcurl') because that would make Meson pass
# --pkg libcurl to valac, and there is no official libcurl VAPI. Instead we
# load our custom VAPI by adding it to the sources and use cc.find_library()
# to link against the C library.
curl_dep = cc.find_library('curl')

###
# Project definition
###
sources = files(
    './src/ffi/libcurl.vapi',
    './src/ffi/curl_shim.c',
    './src/net/fetcher.vala',
    './src/ui/main_window.vala',
    './src/main.vala'
)

include_dirs = include_directories(
  './src/include/'
)

executable('kindlerss',
    sources,
    include_directories: include_dirs,
    dependencies: [gtk_dep, glib_dep, curl_dep]
)
