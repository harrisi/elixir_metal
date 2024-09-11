#ifndef HANDLE_CONVERTER_H
#define HANDLE_CONVERTER_H

#include <erl_nif.h>

#ifdef __APPLE__
#import <Cocoa/Cocoa.h>
typedef NSView* NativeHandle;
#elif _WIN32
#include <windows.h>
typedef HWND NativeHandle;
#else
#include <gtk/gtk.h>
typedef GtkWidget* NativeHandle;
#endif

static ERL_NIF_TERM convert_to_native_handle(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

#endif