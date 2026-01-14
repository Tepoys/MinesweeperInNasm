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
extern promptUserNumberInput
extern minesweeper

%define EASY_DIM 9
%define EASY_MINE 10
%define INTERMEDIATE_DIM 16
%define INTERMEDIATE_MINE 40
%define EXPERT_XDIM 30
%define EXPERT_YDIM 16
%define EXPERT_MINE 99

section .data
  welcome db "Welcome to minesweeper.", 10, "By Tepoys", 10, 0
  menu db "Enter your choice:", 10, "1. Easy 9x9 (10 mines)", 10, "2. Intermediate 16x16 (40 mines)", 10, "3. Expert 30x16 (99 mines)", 10, "4. Quit", 0
  menuXOffset equ 19
  menuYOffset equ 1

  customXPrompt db "Enter the X length:", 0
  customYPrompt db "Enter the Y length:", 0
  customMineCount db "Enter the number of mines:", 0
  
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

  mov dword[input], 0

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

  call parseInput

  jmp .menuLoop


  pop rbp

  mov rax, 60
  mov rdi, 0
  syscall

; rdi - input choice; rax - exit bool (1 = true; 0 = false)
parseInput:
  push rbp
  
  ; set up stack frame
  mov rbp, rsp
  sub rsp, 32

  ; exit bool
  mov qword[rbp-8], 0

  cmp rdi, 1
  je .easy

  cmp rdi, 2
  je .medium

  cmp rdi, 3
  je .hard
  
  cmp rdi, 4
  je .custom

  cmp rdi, 5
  je .quit

.easy:
  mov rdi, EASY_DIM
  mov rsi, EASY_DIM
  mov rdx, EASY_MINE
  call minesweeper
  jmp .return

.medium:
  mov rdi, INTERMEDIATE_DIM
  mov rsi, INTERMEDIATE_DIM
  mov rdx, INTERMEDIATE_MINE
  call minesweeper
  jmp .return

.hard:
  mov rdi, EXPERT_XDIM
  mov rsi, EXPERT_YDIM
  mov rdx, EXPERT_MINE
  call minesweeper
  jmp .return

.custom:
  mov rdi, customXPrompt
  mov qword[rbp - 16], 0
  lea rsi, [rbp-16]
  call promptUserNumberInput

  mov rdi, customYPrompt
  mov qword[rbp - 24], 0
  lea rsi, [rbp-24]
  call promptUserNumberInput

  mov rdi, customMineCount
  mov qword[rbp - 32], 0
  lea rsi, [rbp-32]
  call promptUserNumberInput

  mov rdi, qword[rbp-16]
  mov rsi, qword[rbp-24]
  mov rdx, qword[rbp-32]
  call minesweeper

.quit:
  mov qword[rbp - 8], 1
  jmp .return

.return:
  mov rax, qword[rbp - 8]
  
  sub rsp, 32
  pop rbp

  ret
