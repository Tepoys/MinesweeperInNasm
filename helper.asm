; Tepoys
; Minesweepr in NASM
; helper functions

; no argument, no return
global flushBuffer

; rdi - x position; rsi - y position; no return
global positionCursor

; no argument; no return
global clearScreen

extern getchar
extern printf


section .data
  moveCursor db 0x1B, "[%d;%dH",0
  clearScreenANSI db 0x1B, "[2J", 0x1B, "[H", 0

section .bss
  input resb 1


section .text

; no argument, no return
flushBuffer:
  ; maintain stack alignment
  push rbp

.clearBuffer:

  call getchar
  
  ; check if return char is newline char
  cmp al, 10
  je .EOF

  ; check if returned char is end of file (al = lower 8 bit of rax)
  cmp al, -1
  je .EOF

  jmp .clearBuffer

.EOF:
  pop rbp
  ret

; rdi - x position; rsi - y position; no return
positionCursor:
  push rbp
  
  ; setup printf call
  mov rdx, rdi
  mov rdi, moveCursor
  
  mov rax, 0
  call printf
  
  pop rbp
  ret
  
; no argument; no return
clearScreen:
  push rbp

  ; setup ANSI escape sequence with printf
  xor rax, rax
  mov rdi, clearScreenANSI
  call printf

  pop rbp
  ret
