VULKAN_DIR=modules/vulkan-docs/src
BINDING=target/vulkan.rs
NATIVE_DIR=target/native
TARGET=$(NATIVE_DIR)/test
OBJECTS=$(NATIVE_DIR)/test.o $(NATIVE_DIR)/window.o
LIB_EXTENSION=

RUST_BACKTRACE:=1
BACKEND:=gl

CC=g++
CFLAGS=-std=c++11 -ggdb -O0 -I$(VULKAN_DIR)
DEPS=
LDFLAGS=

ifeq ($(OS),Windows_NT)
	LDFLAGS=
	BACKEND=dx12
	LIB_EXTENSION=dll
else
	UNAME_S:=$(shell uname -s)
	ifeq ($(UNAME_S),Linux)
		LDFLAGS=-lpthread -ldl -lm -lX11 -lxcb
		BACKEND=vulkan
		LIB_EXTENSION=so
	endif
	ifeq ($(UNAME_S),Darwin)
		LDFLAGS=-lpthread -ldl -lm
		BACKEND=metal
		LIB_EXTENSION=dylib
	endif
endif

LIBRARY=target/debug/libportability.$(LIB_EXTENSION)

.PHONY: all binding run

all: $(TARGET)

binding: $(BINDING)

$(BINDING): $(VULKAN_DIR)/vulkan/*.h
	bindgen --no-layout-tests --rustfmt-bindings $(VULKAN_DIR)/vulkan/vulkan.h -o $(BINDING)

$(LIBRARY): libportability/src/*.rs libportability-gfx/src/*.rs Cargo.toml libportability-gfx/Cargo.toml $(wildcard Cargo.lock)
	cargo build --manifest-path libportability/Cargo.toml --features $(BACKEND)
	mkdir -p target/native

$(NATIVE_DIR)/%.o: native/%.cpp $(DEPS) Makefile
	$(CC) -c -o $@ $< $(CFLAGS)

$(TARGET): $(LIBRARY) $(OBJECTS) Makefile
	$(CC) -o $(TARGET) $(OBJECTS) $(LIBRARY) $(LDFLAGS)

run: $(TARGET)
	$(TARGET)

clean:
	rm -f $(OBJECTS) $(TARGET) $(BINDING)
	cargo clean
