; Tepoys
; Minesweeper in NASM
; The main file that manages the minesweeper game.
DEFAULT ABS

%define NULL 0

; rdi - minesweeper x length; rsi - minesweeper y length; rdx - minesweeper mine count
global minesweeper

; rdi - minesweeper x length; rsi - minesweeper y length; rdx - minesweeper mine count; return: memory pointer to the 2d array of size x by y
global generateMines

extern printf
extern malloc
extern free



section .data
  mallocFailedMsg db "Malloc returned null pointer (malloc failure).", 10, "Program exit", 10, 0


section .bss
  map resq 1
  allocState resq 1

section .text
  
minesweeper:
  push rbp

  mov rbp, rsp
  sub rsp, 32





  add rsp, 32
  pop rbp
  ret

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
  mov [rbp - 32], rax
  test rax, rax
  jz mallocFailed

  mov qword[allocState], 0

  ; use r15 as itterator to malloc the rest of the array
  mov r15, [rbp - 24]
  ; use r14 as the array pointer itterator
  mov r14, [rbp - 32]
.allocationLoop:
  ; x size of array
  mov rdi, [rbp - 16]
  call malloc

  test rax, rax
  jz mallocFailed

  mov [r14], rax
  
  ; increment r14 by a qword (8 bytes)
  add r14, 8
  dec r15
  jnz .allocationLoop

  



  

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
