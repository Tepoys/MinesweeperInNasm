; Tepoys
; Minesweeper in NASM
; The part of the program that manages what input mode we are in
; and accepts input when in non canonical mode
DEFAULT ABS

; for vim style controls
%define IDLE 0
%define NUMBER_PREFIX 1
%define COMMAND 2

; valid commands
; could move these to .data for changeable binds later
%define LEFT 'h'
%define RIGHT 'l'
%define DOWN 'j'
%define UP 'k'
%define FLAG 'f'
%define QUIT1 'q'
%define QUIT2 'y'
%define REVEAL 'g'
%define HELP 'a'
%define ABSOLUTE_X 'x'
%define ABSOLUTE_Y 'y'

%define STDIN   0
%define STDOUT  1

%define SYS_READ     0
%define SYS_WRITE    1
%define SYS_IOCTL    16

; ioctl requests
%define TCGETS 0x5401
%define TCSETS 0x5402

; termios flags
%define ICANON 0x0002
%define ECHO   0x0008

extern printf


extern clearScreen

section .text
helpText db "This is the help menu, you can exit by pressing any key.", 10
         db "-----------------------MISC. keys-----------------------", 10
         db "'q' then 'y' to exit", 10, 10
         db "'a' to enter this help menu", 10, 10
         db "-----------------------ActionKeys-----------------------", 10
         db "-- Relative Controls", 10
         db "You can prefix the below with numbers (ie. 5k moves up 5)", 10
         db "'h' - move left", 10, 10
         db "'j' - move down", 10, 10
         db "'k' - move up", 10, 10
         db "'l' - move right", 10, 10
         db "-- Absolute Controls", 10
         db "You can prefix the below with numbers(12x moves to col12)", 10
         db "'x' - moves to a specific column", 10
         db "    - by itself will move to column 0", 10, 10
         db "'y' - moves to a specific row", 10
         db "    - by itself will move to row 0", 10, 10
         db "-- Minesweeper actions"
         db "'f' - flags the highlighted square (if possible)", 10, 10
         db "'g' - reveals the highlighted square (if possible)", 10
         db "---------------------------------------------------------", 10
         db "Press any key to continue", 10, 0
mask db "                                                    ", 0
reminder db "You can press 'a' to view the list of commands.", 0
quitConfirm db "Are you sure you want to quit (press y).", 0

section .bss
; termios settings
termios_old:  resb 60
termios_new:  resb 60

; input buffer
input_byte:   resb 1

; controls
state resb 1
prefixNumber resd 1
inputFailCount resb 1
quitState resb 1

section .text

startGame:
  push rbp

  ; switch to non canonoical mode
  ;
  ; retrieve current settings
  mov rax, SYS_IOCTL
  mov rdi, STDIN
  mov rsi, TCGETS
  mov rdx, termios_old
  syscall

  ; copy settings
  mov rcx, 60
  mov rsi, termios_old
  mov rdi, termios_new
  rep movsb

  ; disable canonical mode and terminal echo
  mov eax, dword[termios_new + 12]
  and eax, ~(ICANON | ECHO)
  mov dword[termios_new + 12], eax

  ; apply new settings
  mov rax, SYS_IOCTL
  mov rdi, STDIN
  mov rsi, TCSETS
  mov rdx, termios_new
  syscall

.read_loop:
  call readChar

  cmp al, '0'
  jb .notNumber
  cmp al, '9'
  ja .notNumber
  jmp .number

.number:
  cmp byte[state], IDLE
  je .numberIdle
  cmp byte[state], NUMBER_PREFIX
  je .numberPrefix

.numberIdle:
  push rax
  sub al, '0'
  mov dword[prefixNumber], eax
  pop rax
  jmp .finishedProcessing

.numberPrefix:
  ; multiply previous prefix number by 10
  ; handle overflow just in case
  push rax
  mov rcx, rax
  movzx rdi, dword[prefixNumber]
  mov rax, 10
  mul edi
  pop rax
  jo .prefixNumberOverflow

  sub cl, '0'
  add dword[prefixNumber], ecx
  jo .prefixNumberOverflow
.overflowReturn:
  jmp .finishedProcessing

.prefixNumberOverflow:
  ; move -1 (max number in two's complement)
  mov dword[prefixNumber], -1
  jmp .overflowReturn

.notNumber:
  ;check for valid command
  cmp al, QUIT1
  je .quit1

  cmp al, QUIT2 ; or absolute_y
  je .quit2OrAbsY

  cmp al, HELP
  je .displayHelp

  cmp al, FLAG
  je .flagCurrentSquare

  cmp al, REVEAL
  je .revealCurrentSquare

  cmp al, ABSOLUTE_X
  je .absX

  cmp al, LEFT
  je .moveLeft

  cmp al, RIGHT
  je .moveRight

  cmp al, UP
  je .moveUp

  cmp al, DOWN
  je .moveDown

.moveDown:
  ; TODO
  jmp .validCommand

.moveUp:
  ; TODO
  jmp .validCommand


.moveRight:
  ; TODO
  jmp .validCommand

.moveLeft:
  ; TODO
  jmp .validCommand

.flagCurrentSquare:
  ; TODO
  jmp .validCommand

.revealCurrentSquare:
  ;TODO
  jmp .validCommand

.absY:
  ; TODO
  jmp .validCommand

.absX:
  ; TODO
  jmp .validCommand


.displayHelp:
  ; call help
  mov rdi, reminder
  jmp .validCommand

.quit1:
  mov byte[quitState], 1
  mov rdi, quitConfirm
  jmp .validCommand

.quit2OrAbsY:
  cmp byte[quitState], 1
  je .quitCurrentGame
  jmp .absY

.finishedProcessing:
  jmp .read_loop

.invalidInput:
  inc byte[inputFailCount]
  cmp byte[inputFailCount], 1
  jl .firstInvalid

  ; second+ invalid
  mov rdi, reminder
  jmp .validCommand

.firstInvalid:
  mov rdi, mask
  jmp .validCommand

.validCommand:
  jmp .read_loop

.quitCurrentGame:
  ; TODO, call cleanup
  jmp .restore

.restore:
  ; restore original terminal settings
  mov rax, SYS_IOCTL
  mov rdi, STDIN
  mov rsi, TCSETS
  mov rdx, termios_new
  syscall

  pop rbp
  ret

; no arguments
; no returns
help:
  push rbp

  call clearScreen
  mov rdi, helpText
  call printf

  pop rbp
  ret

; no arguments
; returns one character from the terminal
readChar:
  mov rax, SYS_READ
  mov rdi, STDIN
  mov rsi, input_byte
  mov rdx, 1
  syscall

  movzx rax, byte[input_byte]
  ret

