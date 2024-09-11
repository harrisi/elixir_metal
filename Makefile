ERLANG_PATH = $(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)
CFLAGS = -I$(ERLANG_PATH) -fno-common -g -arch arm64 -isysroot $(shell xcrun --sdk macosx --show-sdk-path)
OBJC_FLAGS = $(CFLAGS)
LDFLAGS = -framework Cocoa -framework Foundation -framework Metal -framework QuartzCore

METAL_SOURCES = $(wildcard c_src/*.metal)
METAL_OBJECTS = $(METAL_SOURCES:.metal=.air)
METAL_LIBRARY = priv/default.metallib

all: priv/handle_converter.so priv/metal_renderer.so

priv/handle_converter.so: c_src/handle_converter.m
	$(CC) $(OBJC_FLAGS) -o $@ $< $(LDFLAGS) -shared -undefined dynamic_lookup -ObjC

priv/metal_renderer.so: c_src/metal_renderer.m $(METAL_LIBRARY)
	$(CC) $(OBJC_FLAGS) -o $@ $< $(LDFLAGS) -shared -undefined dynamic_lookup -ObjC

$(METAL_LIBRARY): $(METAL_OBJECTS)
	xcrun metallib -o $@ $^

%.air: %.metal
	xcrun metal -c $< -o $@

clean:
	rm -f priv/handle_converter.so priv/metal_renderer.so
