; Tepoys
; Minesweepr in NASM
; helper functions
DEFAULT ABS

; no argument, no return
global flushBuffer

; rdi - x position; rsi - y position; no return
global positionCursor

; no argument; no return
global clearScreen

; rdi - prompt; rsi - pointer to memory; return: 1 success; 0 failure
global promptUserNumberInput

; no argument; no return
global flushSTDOUT

extern getchar
extern printf
extern scanf
extern fflush
extern stdout


section .data
  moveCursor db 0x1B, "[%d;%dH", 0
  clearScreenANSI db 0x1B, "[2J", 0x1B, "[H", 0
  numberInputFormat db "%u", 0
  invalidInputWarn db "Invalid input, try again.", 0

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

  call flushSTDOUT

  pop rbp
  ret

; rdi - prompt; rsi - pointer to memory; return: 1 success; 0 failure
promptUserNumberInput:
  push rbp

  ; set up local stack frame
  mov rbp, rsp
  sub rsp, 32

  mov qword[rbp - 8], rdi
  mov qword[rbp - 16], rsi
  
.loop:
  mov rax, 0
  mov rdi, qword[rbp - 8]
  call printf

  mov rax, 0
  mov rdi, numberInputFormat
  mov rsi, qword[rbp - 16]
  call scanf

  ; store return from scanf
  mov qword[rbp - 24], rax

  call flushBuffer
  
  ; check if return from scanf was a failure
  cmp qword[rbp - 24], 0
  ; if it failed, retry input
  je .invalidInput
  jmp .exitLoop


.invalidInput:
  mov rax, 0
  mov rdi, invalidInputWarn
  call printf
  jmp .loop

.exitLoop:
  ; check if EOF
  cmp qword[rbp - 24], -1
  je .reachedEOF
  jmp .success

; set return values
.reachedEOF:
  mov rax, 0
  jmp .end

.success:
  mov rax, 1
  jmp .end

  ; reset stack
.end:
  add rsp, 32
  pop rbp

  ret

flushSTDOUT:
  push rbp

  mov rdi, [stdout]
  call fflush

  pop rbp
  ret
