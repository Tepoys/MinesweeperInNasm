# Minesweeper in NASM
This is a hobby project for a minesweeper game in NASM built for x86_64 linux.
Some default c functions called (malloc, printf) but all logic writen in assembly.

## How to download
Your terminal must be able to support 256 color.
You can check by runing:
```bash
echo $TERM
```
You will need the following tools installed.
```
nasm
gcc
make
```
Clone this git repository.
```bash
git clone https://github.com/Tepoys/MinesweeperInNasm
```
Head into the folder you installed and compile the assembly.
```bash
cd Your/Folder
make MinesweeperInNasm
```
And finally, run the program:
```bash
./MinesweeperInNasm
```
Have fun!
