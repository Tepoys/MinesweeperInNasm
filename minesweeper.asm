; Tepoys
; Minesweeper in NASM
; The main file that manages the minesweeper game.
DEFAULT ABS

%define NULL 0

%define MINE -1
%define ZERO_UNREVEALED 0
%define ONE_UNREVEALED 1
%define TWO_UNREVEALED 2
%define THREE_UNREVEALED 3
%define FOUR_UNREVEALED 4
%define FIVE_UNREVEALED 5
%define SIX_UNREVEALED 6
%define SEVEN_UNREVEALED 7
%define EIGHT_UNREVEALED 8
; %define ZERO_REVEALED 10
; for itterating over 0 chunks to auto display numbers
%define ZERO_REVEALED_ITTERATED 32
%define ONE_REVEALED 11
%define TWO_REVEALED 12
%define THREE_REVEALED 13
%define FOUR_REVEALED 14
%define FIVE_REVEALED 15
%define SIX_REVEALED 16
%define SEVEN_REVEALED 17
%define EIGHT_REVEALED 18

%define ZERO_FLAGGED 20
%define ONE_FLAGGED 21
%define TWO_FLAGGED 22
%define THREE_FLAGGED 23
%define FOUR_FLAGGED 24
%define FIVE_FLAGGED 25
%define SIX_FLAGGED 26
%define SEVEN_FLAGGED 27
%define EIGHT_FLAGGED 28

%define BOMB_REVEALED 30
%define REAL_BOMB_FLAG 29

; rdi - minesweeper x length; rsi - minesweeper y length; rdx - minesweeper mine count
global minesweeper

; rdi - minesweeper x length; rsi - minesweeper y length; rdx - minesweeper mine count; return: memory pointer to the 2d array of size x by y
global generateMines

; rdi - minefield; rsi - x length; rdx - y length; no returns
; prints minefield to screen
global printMinefield

extern printf
extern malloc
extern free

extern getRand

section .data
  mallocFailedMsg db "Malloc returned null pointer (malloc failure).", 10, "Program exit", 10, 0
  mine db "X ", 0
  noMine db "O ", 0
  printSquareNumber db "%u ", 0
  newLine db 10, 0
  debugMinelayingAttempt db "Attempting to lay mine at (%u,%u)", 10, 0
  background db 0x1B, "[48;5;252m", 0
  hidden db 0x1B, "[48;5;236m", 0x1B, "[38;5;250m", 0
  hiddenText db "[O]", 0
  cursorHighlight db 0x1B, "[48;5;24m", 0x1B, "[38;5;231m", 0
  flag db 0x1B, "[48;5;236m", 0x1B, "[38;5;196m", 0x1B, "[1m", 0
  flagText db "[F]", 0
  bomb db 0x1B, "[48;5;160m", 0x1B, "[38;5;16m", 0x1B, "[1m", 0
  bombText db "[X]", 0
  zero db 0x1B, "[48;5;252m", 0x1B, "[38;5;240m", 0
  zeroText db "[0]", 0
  one db 0x1B, "[38;5;33m", 0
  oneText db "[1]", 0
  two db 0x1B, "[38;5;34m", 0
  twoText db "[2]", 0
  three db 0x1B, "[38;5;196m", 0
  threeText db "[3]", 0
  four db 0x1B, "[38;5;99m", 0
  fourText db "[4]", 0
  five db 0x1B, "[38;5;124m", 0
  fiveText db "[5]", 0
  six db 0x1B, "[38;5;37m", 0
  sixText db "[6]", 0
  seven db 0x1B, "[38;5;238m", 0
  sevenText db "[7]", 0
  eight db 0x1B, "[38;5;250m", 0
  eightText db "[8]", 0
  reset db 0x1B, "[0m", 0
  space db "[ ]", 0


section .bss
  map resq 1
  ; dword since they can go negative (and default int is 32 bit)
  mineCount resd 1
  flagCount resd 1

  y resq 1
  x resq 1
  currentX resq 1
  currentY resq 1
  allocState resq 1

section .text

; rdi - minesweeper x length; rsi - minesweeper y length; rdx - minesweeper mine count
minesweeper:
  push rbp

  mov rbp, rsp
  sub rsp, 32

  mov qword[x], rdi
  mov qword[y], rsi

  call generateMines
  mov qword[map], rax

  mov rdi, qword[map]
  mov rsi, qword[x]
  mov rdx, qword[y]
  call printMinefield

  mov rdi, newLine
  xor rax, rax
  call printf

  mov rdi, qword[map]
  mov rsi, qword[x]
  mov rdx, qword[y]
  call countMines
  
  mov rdi, qword[map]
  mov rsi, qword[x]
  mov rdx, qword[y]
  call printMinefield

  mov rdi, newLine
  xor rax, rax
  call printf

  mov rdi, qword[map]
  mov rsi, qword[x]
  mov rdx, qword[y]
  call printMinefieldSmart

  mov rdi, qword[map]
  mov rsi, qword[x]
  mov rdx, qword[y]
  mov qword[currentX], 5
  mov qword[currentY], 5
  call printMinefieldWithColor

  add rsp, 32
  pop rbp
  ret

; mines represented in the array by -1
; rdi - minesweeper x length; rsi - minesweeper y length; rdx - minesweeper mine count; return: memory pointer to the 2d array of size x by y
generateMines:
  push rbp
  push r14
  push r15

  mov rbp, rsp
  sub rsp, 32
  
  mov qword[allocState], MINE
  
  ; save registers (caller saved)
  mov qword[rbp - 8], rdx ; # mines
  mov qword[rbp - 16], rdi ; x
  mov qword[rbp - 24], rsi ; y

  ; calculate y length (8 byte per memory adress)
  mov rax, 8
  mov rdx, 0
  mul rsi

  mov rdi, rax
  call malloc

  ; save stack counter
  mov qword[rbp - 32], rax
  test rax, rax
  jz mallocFailed

  mov qword[allocState], 0

  ; use r15 as itterator to malloc the rest of the array
  mov r15, qword[rbp - 24]
  ; use r14 as the array pointer itterator
  mov r14, qword[rbp - 32]
.allocationLoop:
  ; x size of array
  mov rdi, qword[rbp - 16]
  call malloc

  test rax, rax
  jz mallocFailed

  ; clear data inside of malloc
  push rax
  push rdi
  mov rdi, qword[rbp-16]
.clearDataLoop:
  mov byte[rax], 0
  
  inc rax
  dec rdi
  jnz .clearDataLoop
  pop rdi
  pop rax
  ;;end clear data

  mov qword[r14], rax
  
  ; increment r14 by a qword (8 bytes)
  add r14, 8
  dec r15
  jnz .allocationLoop

  ; set up mine loop, use r15 as itterator once again
  mov r15, qword[rbp-8]
.minelayingLoop:
  ; generate x random cordinate
  mov rdi, 0
  mov rsi, qword[rbp-16]
  call getRand

  ; store random x cordinate in r14
  movzx r14, eax

  ;generate y random cordinate
  mov rdi, 0
  mov rsi, qword[rbp-24]
  call getRand

; .debugPrint:
;   ; debug
;   push rax
;   push rdi
;   mov rdi, debugMinelayingAttempt
;   mov rsi, r14
;   mov rdx, rax
;   call printf
;   pop rdi
;   pop rax


  ; get the y offset
  mov ecx, 8
  mul ecx

  ; load minefield starting location
  mov rdi, qword[rbp-32]
  ; find the y'th row
  add rdi, rax
  ; get the y'th row at [rdi]
  mov rdi, qword[rdi]
  
  ; find the x'th cell in minefield
  add rdi, r14
  ; load data inside of cell
  mov al, byte[rdi]
  
  ; data is now inside of al

  ; check if there is a mine there
  cmp al, MINE
  je .overlapMine
  jmp .noMine

  ; retry with new random numbers
.overlapMine:
  jmp .minelayingLoop

  ; set square a mine and decrement mine counter
.noMine:
  mov byte[rdi], MINE

  dec r15
  jnz .minelayingLoop

  mov rax, qword[rbp-32]

  add rsp, 32
  pop r15
  pop r14
  pop rbp
  ret 


mallocFailed:
  ; TODO free data and exit
  mov rax, 0
  mov rdi, mallocFailedMsg
  call printf

  mov rax, 60
  mov rdi, 1
  syscall


; rdi - minefield; rsi - x length; rdx - y length; no returns
; prints minefield to screen
printMinefield:
  ; r15 - y pointer; r14 - y length left itterator
  ; r13 - x pointer; r12 - x length left itterator
  push rbp
  push r15
  push r14
  push r13
  push r12
  mov rbp, rsp
  sub rsp, 16

  ; original minefield pointer in r15
  mov r15, rdi
  ; total y length in r14
  mov r14,  rdx

  ; total x length
  mov qword[rbp-8], rsi

.printLoopY:
  ; set up x pointer
  mov r13, qword[r15]
  ; set up x length
  mov r12, qword[rbp-8]

.printLoopX:
  ; itterate over the x column
  cmp byte[r13], MINE
  je .isMine
  jmp .notMine

  ; check if mine
.isMine:
  mov rdi, mine
  jmp .printSquare

.notMine:
  mov rdi, noMine
  jmp .printSquare

  ; print the current square
.printSquare:
  xor rax, rax
  call printf

  ; itterate to the next square
  inc r13 
  dec r12
  jnz .printLoopX

  ; print new line
  xor rax, rax
  mov rdi, newLine
  call printf

  ; end of x loop, itterate over y
  add r15, 8
  dec r14
  jnz .printLoopY
  
  add rsp, 16
  pop r12
  pop r13
  pop r14
  pop r15
  pop rbp
  ret

  ; rdi - minefield; rsi - x length; rdx - y length; no return
  ; counts the mines surounding each square and sets the mine count accordingly
countMines:
  
  push rbp
  push r15
  push r14
  push r13
  push r12
  push rbx

  mov rbp, rsp
  sub rsp, 40
  
  ; r15 - y pointer; r14 - y index
  ; r13 - x pointer; r12 - x index
  mov r15, rdi
  mov r14, 0
.mainYLoop:
  mov r13, qword[r15]
  mov r12, 0

.mainXLoop:

; if current square is mine, skip
cmp byte[r13], MINE
je .skipCountCurrentSquare

; bounds checking to make sure we dont try to look outside of the minefield
.calculateBounds:
  ; r8 - y lowerbound; r9 - y upper bound
  mov r8, r14
  mov r9, r8
  dec r8
  inc r9

  ; rbx - x lower bound; rcx - x upper bound
  mov rbx, r12
  mov rcx, rbx
  dec rbx
  inc rcx

.yLowerBoundCheck:
  cmp r8, 0
  jl .yBoundTooLow
  jmp .yUpperBoundCheck

.yBoundTooLow:
  inc r8
  jmp .xLowerBoundCheck
  
.yUpperBoundCheck:
  cmp r9, rdx
  jge .yBoundTooHigh
  jmp .xLowerBoundCheck

.yBoundTooHigh:
  dec r9
  jmp .xLowerBoundCheck

.xLowerBoundCheck:
  cmp rbx, 0
  jl .xBoundTooLow
  jmp .xUpperBoundCheck

.xBoundTooLow:
  inc rbx
  jmp .endBoundsCheck

.xUpperBoundCheck:
  cmp rcx, rsi
  jge .xBoundTooHigh
  jmp .endBoundsCheck

.xBoundTooHigh:
  dec rcx
  jmp .endBoundsCheck

.endBoundsCheck:
  ; store r15 (originally y pointer), use now as y pointer for inner loop
  mov qword[rbp - 8], r15
  cmp r8, r14
  je .noDecrement
  jmp .decrement

.noDecrement:
  jmp .endSetupBoundPointer

.decrement:
  ; move r15 back by a qword (to the previous pointer)
  sub r15, 8
  jmp .endSetupBoundPointer

; use min bounds for x and y as index (loop until those reach max bounds)
.endSetupBoundPointer:
  ; ; find range of Y
  ; mov r13, r9
  ; sub r13, r8
  ; mov qword[rbp-24], r8
  ;
  ; ; start iterator of x
  ; mov qword[rbp - 16], rbx

  ; create mine counter
  mov qword[rbp - 32], 0
  mov qword[rbp - 40], rbx
  
.mineCountingLoopY:
  mov rbx, qword[rbp - 40]
  ; set up x iterator for x loop
  mov rax, qword[r15]
  ; increment inner x array to starting x index
  add rax, rbx

.mineCountingLoopX:
  cmp byte[rax], MINE
  je .hasMine
  jmp .itterateX

.hasMine:
  ; this is not needed on second thought
  ; ; check if we are considering the current square
  ; cmp rbx, rsi
  ; jne .incrementMineCounter
  ; cmp r8, rdx
  ; je .itterateX
  ; jmp .incrementMineCounter

; .incrementMineCounter:
  inc qword[rbp - 32]
  jmp .itterateX

.itterateX:
  ; increment pointer
  inc rax
  ; increment index
  inc rbx
  ; compare current index (rbx) with max index (rcx)
  cmp rbx, rcx
  jle .mineCountingLoopX

.itterateY:
  ; move to the next x row
  add r15, 8
  ; increment index
  inc r8

  ; compare current index with max index
  cmp r8, r9
  jle .mineCountingLoopY

.countResult:
  ; reset r15
  mov r15, qword[rbp - 8]
  ;result is inside of [rbp-32]
  ; r15 - y pointer; r14 - y index
  ; r13 - x pointer; r12 - x index

  ; move count into square
  mov rax, qword[rbp-32]
  mov byte[r13], al

.skipCountCurrentSquare:
.itterateMainX:
  inc r12
  inc r13

  cmp r12, rsi
  jl .mainXLoop

.itterateMainY:
  add r15, 8
  inc r14

  cmp r14, rdx
  jl .mainYLoop

.finishedCountingAllSquares:
  add rsp, 40
  pop rbx
  pop r12
  pop r13
  pop r14
  pop r15
  pop rbp

  ret

; rdi - minefield; rsi - x length; rdx - y length; no returns
; prints minefield to screen, adds color and also displays
printMinefieldSmart:
  ; r15 - y pointer; r14 - y length left itterator
  ; r13 - x pointer; r12 - x length left itterator
  push rbp
  push r15
  push r14
  push r13
  push r12
  mov rbp, rsp
  sub rsp, 16

  ; original minefield pointer in r15
  mov r15, rdi
  ; total y length in r14
  mov r14,  rdx

  ; total x length
  mov qword[rbp-8], rsi

.printLoopY:
  ; set up x pointer
  mov r13, qword[r15]
  ; set up x length
  mov r12, qword[rbp-8]

.printLoopX:
  ; itterate over the x column
  cmp byte[r13], MINE
  je .isMine
  jmp .notMine

  ; check if mine
.isMine:
  mov rdi, mine
  jmp .printSquare

.notMine:
  mov rdi, printSquareNumber
  movzx rsi, byte[r13]
  jmp .printSquare

  ; print the current square
.printSquare:
  xor rax, rax
  call printf

  ; itterate to the next square
  inc r13 
  dec r12
  jnz .printLoopX

  ; print new line
  xor rax, rax
  mov rdi, newLine
  call printf

  ; end of x loop, itterate over y
  add r15, 8
  dec r14
  jnz .printLoopY
  
  add rsp, 16
  pop r12
  pop r13
  pop r14
  pop r15
  pop rbp
  ret

; rdi - minefield; rsi - x length; rdx - y length; no returns
; assumes player position is stored in currentX and currentY
; prints minefield to screen, adds color and also displays
printMinefieldWithColor:
  ; r15 - y pointer; r14 - y length left itterator
  ; r13 - x pointer; r12 - x length left itterator
  push rbp
  push r15
  push r14
  push r13
  push r12
  mov rbp, rsp
  sub rsp, 32

  ; original minefield pointer in r15
  mov r15, rdi
  ; total y length in r14
  mov r14,  rdx
  ; y itterator
  mov qword[rbp - 24], 0

  ; total x length
  mov qword[rbp-8], rsi

.printLoopY:
  ; set up x pointer
  mov r13, qword[r15]
  ; set up x length
  mov r12, qword[rbp-8]
  ; set up x iterator
  mov qword[rbp - 16], 0

.printLoopX:
  ; check cursor position
  mov rax, qword[currentX]
  cmp rax, qword[rbp-16]
  jne .inconsistentXPosition

  mov rax, qword[currentY]
  cmp rax, qword[rbp-24]
  jne .inconsistentYPosition
  jmp .overrideBackground
.overrideBackground:
  mov rax, 0
  mov rdi, reset
  call printf
  mov rax, 0
  mov rdi, cursorHighlight
  call printf
  ; TODO move to bellow
  
.inconsistentYPosition:
.inconsistentXPosition:
  cmp byte[r13], 10
  jl .unrevealed
  jmp .revealed

.unrevealed:
; potential cheat feature
  xor rax, rax
  mov rdi, hidden
  call printf

  ; print O
  mov rdi, hiddenText
  jmp .printSquare

.revealed:
  cmp byte[r13], ZERO_FLAGGED
  jnge .notFlagged
  cmp byte[r13], REAL_BOMB_FLAG
  jle .hasFlag
  jmp .notFlagged

.notFlagged:
  cmp byte[r13], ZERO_REVEALED_ITTERATED
  je .hasZero
  cmp byte[r13], ONE_REVEALED
  je .hasOne
  cmp byte[r13], TWO_REVEALED
  je .hasTwo
  cmp byte[r13], THREE_REVEALED
  je .hasThree
  cmp byte[r13], FOUR_REVEALED
  je .hasFour
  cmp byte[r13], FIVE_REVEALED
  je .hasFive
  cmp byte[r13], SIX_REVEALED
  je .hasSix
  cmp byte[r13], SEVEN_REVEALED
  je .hasSeven
  cmp byte[r13], EIGHT_REVEALED
  je .hasEight

.hasFlag:
  mov rax, 0
  mov rdi, flag
  call printf

  mov rdi, flagText
  jmp .printSquare

.hasZero:
  mov rax, 0
  mov rdi, zero
  call printf

  mov rdi, zeroText
  jmp .printSquare

.hasOne:
  mov rax, 0
  mov rdi, one
  call printf

  mov rdi, oneText
  jmp .printSquare

.hasTwo:
  mov rax, 0
  mov rdi, two
  call printf

  mov rdi, twoText
  jmp .printSquare

.hasThree:
  mov rax, 0
  mov rdi, three
  call printf

  mov rdi, threeText
  jmp .printSquare

.hasFour:
  mov rax, 0
  mov rdi, four
  call printf

  mov rdi, fourText
  jmp .printSquare

.hasFive:
  mov rax, 0
  mov rdi, five
  call printf

  mov rdi, fiveText
  jmp .printSquare

.hasSix:
  mov rax, 0
  mov rdi, six
  call printf

  mov rdi, sixText
  jmp .printSquare

.hasSeven:
  mov rax, 0
  mov rdi, seven
  call printf

  mov rdi, sevenText
  jmp .printSquare

.hasEight:
  mov rax, 0
  mov rdi, eight
  call printf

  mov rdi, eightText
  jmp .printSquare

  ; print the current square
.printSquare:
  xor rax, rax
  call printf

  xor rax, rax
  mov rdi, background
  ;call printf

  xor rax, rax
  mov rdi, space
  ;call printf

  xor rax, rax
  mov rdi, reset
  call printf

  ; itterate to the next square
  inc r13 
  inc qword[rbp - 16]
  dec r12
  jnz .printLoopX

  ; print new line
  xor rax, rax
  mov rdi, newLine
  call printf

  ; end of x loop, itterate over y
  add r15, 8
  inc qword[rbp  - 24]
  dec r14
  jnz .printLoopY
  
  add rsp, 32
  pop r12
  pop r13
  pop r14
  pop r15
  pop rbp
  ret
