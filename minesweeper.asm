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
%define SEVEN_UNREVEALD 7
%define EIGHT_UNREVEALED 8
%define ZERO_UNREVEALED 0
%define ONE_REVEALED 11
%define TWO_REVEALED 12
%define THREE_REVEALED 13
%define FOUR_REVEALED 14
%define FIVE_REVEALED 15
%define SIX_REVEALED 16
%define SEVEN_REVEALD 17
%define EIGHT_REVEALED 18

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
  mine db "X", 0
  noMine db "O", 0
  newLine db 10, 0
  debugMinelayingAttempt db "Attempting to lay mine at (%u,%u)", 10, 0

section .bss
  map resq 1
  y resq 1
  x resq 1
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
  mov [map], rax

  mov rdi, qword[map]
  mov rsi, qword[x]
  mov rdx, qword[y]
  call printMinefield

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
  
  mov qword[allocState], -1
  
  ; save registers (caller saved)
  mov [rbp - 8], rdx ; # mines
  mov [rbp - 16], rdi ; x
  mov [rbp - 24], rsi ; y

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
  
.debugPrint:
  ; debug
  push rax
  push rdi
  mov rdi, debugMinelayingAttempt
  mov rsi, r14
  mov rdx, rax
  call printf
  pop rdi
  pop rax


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
  cmp al, -1
  je .overlapMine
  jmp .noMine

  ; retry with new random numbers
.overlapMine:
  jmp .minelayingLoop

  ; set square a mine and decrement mine counter
.noMine:
  mov byte[rdi], -1

  dec r15
  jnz .minelayingLoop

  mov rax, [rbp-32]

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
