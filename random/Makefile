APPS=demo1 demo2
DMD=/home/elcuco/src/d/dmd/linux/bin/dmd

.PHONY: all clean

all: $(APPS)

clean:
	rm -f $(APPS)
	rm -f *.o
	
# demo1
demo1: demo1.d
	$(DMD) $?
	
# demo2
foo_c.lst: foo_c.h
	gcc $? -E -o $@
	
foo_c.o: foo_c.c
	$(CC) $(CFLAGS) -c $? -o $@
	
demo2: foo_c.o
	echo "1111111"