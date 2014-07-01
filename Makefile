
pi=192.168.1.13

rust_src:=$(wildcard src/*.rs)
rust_programs:=$(patsubst src/%.rs,out/%,$(filter-out %-err.rs,$(rust_src)))
rust_compile_errors:=$(patsubst src/%-err.rs,out/error/%.txt,$(rust_src))

book_src:=$(wildcard doc/*.asciidoc)
book_images:=$(wildcard doc/*.svg doc/*.jpg doc/*.png)

version:=$(shell git describe --tags --always --dirty=-local --match='v*' | sed -e 's/^v//')

asciidoc_icondir=/usr/share/asciidoc/icons
asciidoc_icons:=$(shell find $(asciidoc_icondir) -type f -name '*.*')

linker=../tools/arm-bcm2708/arm-bcm2708hardfp-linux-gnueabi/bin/arm-bcm2708hardfp-linux-gnueabi-g++
rustflags=-L . --target arm-unknown-linux-gnueabihf -C linker=$(linker)

all: pdf $(rust_programs)

pdf: out/pdf/book.pdf

out/pdf/book.pdf: out/docbook/book.xml
	@mkdir -p $(dir $@)
	dblatex -o $@ --fig-path=doc -P latex.encoding=utf8 $<

out/docbook/book.xml: $(book_src) $(rust_src) $(rust_compile_errors)
	@mkdir -p $(dir $@)
	asciidoc \
		-a icons \
		-a version="$(version)" \
		-b docbook45 \
		-o $@ doc/book.asciidoc

out/%: src/%.rs
	@mkdir -p $(dir $@)
	rustc $(rustflags) -o $@ $<

out/error/%.txt: src/%-err.rs
	@mkdir -p $(dir $@)
	-rustc $(rustflags) -o $(dir $@)/$* $< > $@ 2>&1

deployed: $(rust_programs)
	rsync $^ $(pi):

clean:
	rm -rf out/

again: clean deployed

.PHONY: all pdf deployed clean again tmp
