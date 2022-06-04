bf: bf.o
	ld -o bf bf.o

bf.o: bf.asm
	yasm -f elf64 -m amd64 -g dwarf2 bf.asm

clean:
	rm bf.o
