.PHONY: menu.o helper.o minesweeper.o nonCanonicalIO.o run r runDebug rd

MinesweeperInNasm: helper.o menu.o minesweeper.o nonCanonicalIO.o
	gcc -m64 -no-pie -o MinesweeperInNasm helper.o menu.o minesweeper.o nonCanonicalIO.o

MinesweeperInNasmDebug: helperDebug.o menuDebug.o minesweeperDebug.o nonCanonicalIODebug.o
	gcc -m64 -no-pie -g -o MinesweeperInNasmDebug helperDebug.o menuDebug.o minesweeperDebug.o nonCanonicalIODebug.o

menuDebug.o: menu.asm
	nasm -f elf64 -F dwarf -l menu.lst -o menuDebug.o menu.asm

menu.o: menu.asm
	nasm -f elf64 menu.asm

helper.o: helper.asm
	nasm -f elf64 helper.asm

helperDebug.o: helper.asm
	nasm -f elf64 -F dwarf -l helper.lst -o helperDebug.o helper.asm

minesweeper.o: minesweeper.asm
	nasm -f elf64 minesweeper.asm

minesweeperDebug.o: minesweeper.asm
	nasm -f elf64 -F dwarf -l minesweeper.lst -o minesweeperDebug.o minesweeper.asm

nonCanonicalIO.o: nonCanonicalIO.asm
	nasm -f elf64 nonCanonicalIO.asm

nonCanonicalIODebug.o: nonCanonicalIO.asm
	nasm -f elf64 -F dwarf -l nonCanonicalIO.lst -o nonCanonicalIODebug.o nonCanonicalIO.asm

run r: MinesweeperInNasm
	./MinesweeperInNasm

runDebug rd: MinesweeperInNasmDebug
	./MinesweeperInNasmDebug

clean:
	rm *.o *.lst
