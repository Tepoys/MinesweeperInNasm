.PHONY: menu.o helper.o run r runDebug rd

MinesweeperInNasm: helper.o menu.o
	gcc -m64 -no-pie -o MinesweeperInNasm helper.o menu.o

MinesweeperInNasmDebug: helperDebug.o menuDebug.o
	gcc -m64 -no-pie -g -o MinesweeperInNasmDebug helperDebug.o menuDebug.o

menuDebug.o: menu.asm
	nasm -f elf64 -F dwarf -l menu.lst -o menuDebug.o menu.asm

menu.o: menu.asm
	nasm -f elf64 menu.asm

helper.o: helper.asm
	nasm -f elf64 helper.asm

helperDebug.o: helper.asm
	nasm -f elf64 -F dwarf -l helper.lst -o helperDebug.o helper.asm

run r: MinesweeperInNasm
	./MinesweeperInNasm

runDebug rd: MinesweeperInNasmDebug
	./MinesweeperInNasmDebug

clean:
	rm *.o *.lst
