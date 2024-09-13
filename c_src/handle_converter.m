#include "handle_converter.h"
#include <stdio.h>

static ERL_NIF_TERM convert_to_native_handle(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  if (argc != 1) {
    return enif_make_badarg(env);
  }

  unsigned long wx_handle;
  if (!enif_get_uint64(env, argv[0], &wx_handle)) {
    return enif_make_badarg(env);
  }

  NativeHandle native_handle = (NativeHandle)wx_handle;

#ifdef __APPLE__
  if (![native_handle isKindOfClass:[NSView class]]) {
    return enif_make_tuple2(env, enif_make_atom(env, "error"), enif_make_atom(env, "invalid_handle"));
  }
  printf("Converted to NSView: %p\n", native_handle);
#elif defined(_WIN32)
  if (!IsWindow(native_handle)) {
    return enif_make_tuple2(env, enif_make_atom(env, "error"), enif_make_atom(env, "invalid_handle"));
  }
  printf("Converted to HWND: %p\n", native_handle);
#else
  if (!GTK_IS_WIDGET(native_handle)) {
    return enif_make_tuple2(env, enif_make_atom(env, "error"), enif_make_atom(env, "invalid_handle"));
  }
  printf("Converted to GTK_WIDGET: %p\n", native_handle);
#endif

  return enif_make_tuple2(env, enif_make_atom(env, "ok"), enif_make_uint64(env, (unsigned long)native_handle));
}

static ErlNifFunc nif_funcs[] = {
  {"convert_to_native_handle", 1, convert_to_native_handle}
};

ERL_NIF_INIT(Elixir.ElixirMetal.HandleConverter, nif_funcs, NULL, NULL, NULL, NULL)
