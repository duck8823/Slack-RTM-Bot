build:
	perl Build.PL && ./Build

test: build
	./Build test
