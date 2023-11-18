default: all

all:
	./docs/build-readme.raku
	mi6 build

debug:
	raku -Ilib ./bin/photo 
