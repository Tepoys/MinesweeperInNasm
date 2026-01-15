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

extern printf
extern malloc
extern free

extern getRand



section .data
  mallocFailedMsg db "Malloc returned null pointer (malloc failure).", 10, "Program exit", 10, 0


section .bss
  map resq 1
  allocState resq 1

section .text

; rdi - minesweeper x length; rsi - minesweeper y length; rdx - minesweeper mine count
minesweeper:
  push rbp

  mov rbp, rsp
  sub rsp, 32

  call generateMines
  mov [map], rbp

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
  add rdi, r15
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
