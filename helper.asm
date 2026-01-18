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

; no arguments; no return
global seedRand

; rdi - lower bound; rsi - upper bound; no return
global getRand

global setCursorPositionHome

extern getchar
extern printf
extern scanf
extern fflush
extern stdout
extern time
extern srand
extern rand

section .data
  moveCursor db 0x1B, "[%d;%dH", 0
  clearScreenANSI db 0x1B, "[2J", 0x1B, "[H", 0
  numberInputFormat db "%u", 0
  invalidInputWarn db "Invalid input, try again.", 10, 0
  tooLowWarn db "Your input was too low (min: %d)", 10, 0
  tooHighWarn db "Your input was too high (max: %d)", 10, 0
  resetCursorPosition db 0x1B, "[H", 0

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

; rdi - prompt; rsi - pointer to memory; rdx - lower bounds; rcx - upper bounds; return: 1 success; 0 failure
promptUserNumberInput:
  push rbp

  ; set up local stack frame
  mov rbp, rsp
  sub rsp, 48

  mov qword[rbp - 8], rdi
  mov qword[rbp - 16], rsi
  mov qword[rbp - 40], rdx
  mov qword[rbp - 48], rcx
  
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

; succesfully gotten user number input
.success:

  ; check if number is within bounds
  ; lower bound
  mov rsi, qword[rbp - 16]
  mov rsi, [rsi]
  cmp rsi, qword[rbp - 40]
  jl .tooLow
  jmp .checkUpperBound

.tooLow:
  mov rdi, tooLowWarn
  xor rax, rax
  mov rsi, [rbp - 40]
  call printf
  jmp .loop

.checkUpperBound:
  cmp rsi, qword[rbp - 48]
  jg .tooHigh
  jmp .passBoundsCheck

.tooHigh:
  mov rdi, tooHighWarn
  xor rax, rax
  mov rsi, [rbp - 48]
  call printf
  jmp .loop

.passBoundsCheck:

  mov rax, 1
  jmp .end

  ; reset stack
.end:
  add rsp, 48
  pop rbp

  ret

; no arguments; no return
flushSTDOUT:
  push rbp

  mov rdi, [stdout]
  call fflush

  pop rbp
  ret

seedRand:
  push rbp

  mov rdi, 0
  call time

  mov rdi, rax
  call srand

  pop rbp
  ret

; rdi - lower bound; rsi - upper bound; no return
getRand:
  push rbp
  mov rbp, rsp
  sub rsp,  16

  mov qword[rbp-8], rdi
  mov qword[rbp-16], rsi

  call rand

  ; set up division to get rand within bounds
  mov ecx, dword[rbp-16]
  sub ecx, dword[rbp-8]

  xor edx, edx
  div ecx

  ; remainder in edx
  mov eax, edx

  add rsp, 16
  pop rbp
  ret

setCursorPositionHome:
  push rbp

  mov rdi, resetCursorPosition
  xor rax, rax
  call printf

  pop rbp
  ret
