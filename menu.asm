; Tepoys
; Minesweeper in NASM
; Menu for user input; the entry point.
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
  firstDisplay resb 1

section .text
  global main

main:
  ; align stack frame (16 aligned)
  push rbp

  ; different cursor position on first menu
  mov byte[firstDisplay], 1

  call clearScreen

  mov rax, 0
  mov rdi, welcome
  call printf

.menuLoop:
  mov rax, 0
  mov rdi, menu
  call printf

  ; compute Y offset using firstDisplay
  mov rsi, menuYOffset

  movzx rax, byte[firstDisplay]
  test rax, rax
  jz .notFirstTime
  jmp .firstTime

.firstTime:
  add rsi, 2
  mov byte[firstDisplay], 0
  jmp main.notFirstTime

.notFirstTime:
  mov rdi, menuXOffset
  call positionCursor

  mov rax, 0
  mov rdi, inputFormat
  mov rsi, input
  call scanf
  call flushBuffer

  call clearScreen
  jmp .menuLoop


  pop rbp

  mov rax, 60
  mov rdi, 0
  syscall
