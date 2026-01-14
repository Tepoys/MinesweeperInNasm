; Tepoys
; Minesweeper in NASM
; Menu for user input
DEFAULT ABS

extern printf
extern scanf
extern flushBuffer
extern generateMines
extern positionCursor
extern clearScreen

section .data
  welcome db "Welcome to minesweeper.", 10, "By Tepoys", 10, 0
  menu db "Enter your choice:", 10, "1. Easy 9x9 (10 mines)", 10, "2. Intermediate 16x16 (40 mines)", 10, "3. Expert 30x16 (99 mines)", 10, "4. Quit", 0
  menuXOffset equ 19
  menuYOffset equ 1
  
  inputFormat db "%u", 0
  outputFormat db "%u", 10, 0


section .bss
  input resd 1

section .text
  global main

main:
  ; align stack frame (16 aligned)
  push rbp
  
  call clearScreen

  mov rax, 0
  mov rdi, welcome
  call printf

  mov rax, 0
  mov rdi, menu
  call printf

  mov rdi, menuXOffset
  mov rsi, menuYOffset+2
  call positionCursor

  mov rax, 0
  mov rdi, inputFormat
  mov rsi, input
  call scanf

  call clearScreen

printInput:
  mov rax, 0
  mov rdi, outputFormat
  movzx rsi, dword[input]
  call printf
  
;  call clearScreen

  pop rbp

  mov rax, 60
  mov rdi, 0
  syscall
