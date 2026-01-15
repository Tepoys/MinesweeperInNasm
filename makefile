.PHONY: menu.o helper.o run r runDebug rd

MinesweeperInNasm: helper.o menu.o minesweeper.o
	gcc -m64 -no-pie -o MinesweeperInNasm helper.o menu.o minesweeper.o

MinesweeperInNasmDebug: helperDebug.o menuDebug.o minesweeperDebug.o
	gcc -m64 -no-pie -g -o MinesweeperInNasmDebug helperDebug.o menuDebug.o minesweeperDebug.o

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

run r: MinesweeperInNasm
	./MinesweeperInNasm

runDebug rd: MinesweeperInNasmDebug
	./MinesweeperInNasmDebug

clean:
	rm *.o *.lst
