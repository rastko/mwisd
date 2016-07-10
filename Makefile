all:	
	cd ext/cli; make all
	rake compile

install:
	cd ext/cli; make install

clean:
	cd ext/cli; make clean
	rake clean

cleanall:	clean
	cd ext/cli; make cleanall

