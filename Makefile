SRC_COFFEE = $(shell find src -name '*.coffee')
SRC_JS = $(shell find src -name '*.js')
LIB = $(SRC_COFFEE:src/%.coffee=lib/%.js) $(SRC_JS:src/%.js=lib/%.js)

all: lib

run: all
	@./bin/songlocator

lib: $(LIB)
watch:
	coffee -bc --watch -o lib src

lib/%.js: src/%.js
	@echo `date "+%H:%M:%S"` - compiled $<
	@cp $< $@

lib/%.js: src/%.coffee
	@echo `date "+%H:%M:%S"` - compiled $<
	@mkdir -p $(@D)
	@coffee -bcp $< > $@

clean:
	rm -rf $(LIB)
