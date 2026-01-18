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

%define GAME_IDLE 0
%define GAME_LOST 1
%define GAME_WON 2

extern printf

extern clearScreen

; import all UI related minesweeper functions
extern revealWrapper
extern flagWrapper

extern moveLeftMinesweeper
extern moveRightMinesweeper
extern moveDownMinesweeper
extern moveUpMinesweeper

extern toX
extern toY

extern displayUI

extern hasWon

global startGame

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
         db "-- Minesweeper actions", 10
         db "'f' - flags the highlighted square (if possible)", 10, 10
         db "'g' - reveals the highlighted square (if possible)", 10
         db "---------------------------------------------------------", 10
         db "Press any key to continue", 10, 0
mask db "                                                    ", 10, 0
reminder db "You can press 'a' to view the list of commands.", 10, 0
quitConfirm db "Are you sure you want to quit (press y).", 10, 0


; input reactions ----
successToggleFlag db "Toggled flag.", 10, 0
failureToggleFlag db "Can not flag current square.", 10, 0
firstMoveFlagWarn db "Can not toggle flag on first move.", 10, 0

validRevealText db "Revealed square.", 10, 0
invalidRevealText db "Can not reveal square.", 10, 0

gameWonText db "Congratultions, you won!", 10, "Press q to quit", 10, 0
gameLostText db "You lost! Better luck next time.", 10, "Press q to quit", 10, 0

moveLeftText db "Moved left by %u.", 10, 0
moveRightText db "Moved right by %u.", 10, 0
moveUpText db "Moved up by %u.", 10, 0
moveDownText db "Moved down by %u.", 10, 0

movedToY db "Moved to y=%d", 10, 0
movedToX db "Moved to x=%d", 10, 0

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

; forgot to add a game stat in minesweeper.asm
gameState resb 1

currentCommandCount resb 1
currentCommand resb 1

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

  mov byte[gameState], GAME_IDLE
  mov dword[prefixNumber], 0
  mov byte[inputFailCount], 0
  mov byte[quitState], 0
  mov byte[state], IDLE

  mov rdi, mask
  call displayUI

.read_loop:
  call readChar

  mov byte[currentCommand], al

  cmp byte[gameState], GAME_WON
  je .checkExit
  cmp byte[gameState], GAME_LOST
  je .checkExit
  jmp .continueCheckInput

.checkExit:
  cmp al, 'q'
  je .quitCurrentGame
  jmp .read_loop

.continueCheckInput:
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
  mov byte[state], NUMBER_PREFIX
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
  jmp .invalidInput

.moveDown:
  movzx rdi, dword[prefixNumber]
  cmp rdi, 0
  jne .normalDown
  inc rdi
.normalDown:
  mov dword[prefixNumber], edi
  call moveDownMinesweeper
  mov rdi, moveDownText
  mov esi, dword[prefixNumber]
  jmp .validCommand

.moveUp:
  movzx rdi, dword[prefixNumber]
  cmp rdi, 0
  jne .normalUp
  inc rdi
.normalUp:
  mov dword[prefixNumber], edi
  call moveUpMinesweeper
  mov rdi, moveUpText
  mov esi, dword[prefixNumber]
  jmp .validCommand

.moveRight:
  movzx rdi, dword[prefixNumber]
  cmp rdi, 0
  jne .normalRight
  inc rdi
.normalRight:
  mov dword[prefixNumber], edi
  call moveRightMinesweeper
  mov rdi, moveRightText
  mov esi, dword[prefixNumber]
  jmp .validCommand

.moveLeft:
  movzx rdi, dword[prefixNumber]
  cmp rdi, 0
  jne .normalLeft
  inc rdi
.normalLeft:
  mov dword[prefixNumber], edi
  call moveLeftMinesweeper
  mov rdi, moveLeftText
  mov esi, dword[prefixNumber]
  jmp .validCommand

;----------------------------------------

.flagCurrentSquare:
  call flagWrapper

  cmp rax, 2
  je .firstMoveFlag

  cmp rax, 0
  je .toggleSuccess
  mov rdi, failureToggleFlag
  jmp .endFlagCurrentSquare

.toggleSuccess:
  mov rdi, successToggleFlag
  jmp .endFlagCurrentSquare

.firstMoveFlag:
  mov rdi, firstMoveFlagWarn
  jmp .endFlagCurrentSquare

.endFlagCurrentSquare:
  jmp .validCommand

;----------------------------------------

.revealCurrentSquare:
  call revealWrapper

  cmp rax, 1
  je .gameLost

  cmp rax, 0
  je .validReveal
  jmp .invalidReveal

.validReveal:
  mov rdi, validRevealText
  call hasWon
  cmp rax, 1
  je .gameWon
  mov rdi, validRevealText
  jmp .endRevealCurrentSquare

.invalidReveal:
  mov rdi, invalidRevealText
  jmp .endRevealCurrentSquare

.endRevealCurrentSquare:
  jmp .validCommand

;----------------------------------------

.absY:
  movzx rdi, dword[prefixNumber]
  call toY
  mov rdi, movedToY
  movzx rsi, dword[prefixNumber]
  jmp .validCommand

;----------------------------------------

.absX:
  movzx rdi, dword[prefixNumber]
  call toX
  mov rdi, movedToX
  movzx rsi, dword[prefixNumber]
  jmp .validCommand

;----------------------------------------


.gameLost:
  mov byte[gameState], GAME_LOST
  mov rdi, gameLostText
  call displayUI
  jmp .read_loop

.gameWon:
  mov byte[gameState], GAME_WON
  mov rdi, gameWonText
  call displayUI
  jmp .read_loop

.displayHelp:
  call help
  mov rdi, reminder
  jmp .validCommand

.quit1:
  mov byte[quitState], 1
  mov rdi, quitConfirm
  call displayUI
  jmp .read_loop

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
  jmp .read_loop

.validCommand:
  call displayUI
  mov dword[prefixNumber], 0
  mov byte[inputFailCount], 0
  mov byte[quitState], 0
  mov byte[state], IDLE
  jmp .read_loop

.quitCurrentGame:
  ; TODO, call cleanup
  jmp .restore

.restore:
  ; restore original terminal settings
  mov rax, SYS_IOCTL
  mov rdi, STDIN
  mov rsi, TCSETS
  mov rdx, termios_old
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

  call readChar
  call clearScreen

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

