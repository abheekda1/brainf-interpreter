section .data
  not_enough_arg_text db "please add the bf path as an argument!",0x0,0x0a
  not_enough_arg_len equ $-not_enough_arg_text ; 40
  bufsize dw 1024

  O_RDONLY equ 0
  O_WRONLY equ 1
  O_RDWR   equ 2

  NUM_CELLS equ 30000

  FALSE equ 0
  TRUE  equ 1

  EXIT_SUCCESS equ 0
  EXIT_FAILURE equ 1

section .bss
  path  resb 16
  buf   resb 1024
  fd_in resb 1
  current_char resb 1
  in_brackets  resb 1

  cells resb NUM_CELLS

  left_bracket_stack resb 32
  left_bracket_sp    resb 1

  num_to_match_right_bracket resb 1

  argc    resb 1
  bf_file resb 16 ; max file name length is 16

section .text
  global _start ; define entrypoint for ld

_start:
  pop rsi ; get argc
  cmp rsi, 2
  jl  _not_enough_args
  pop rcx ; discard program name

  mov byte [left_bracket_sp], 0
  mov byte [num_to_match_right_bracket], 0

  pop rdi ; get first argument for _open_file
  push rdi
  push rcx
  push rsi ; ^^^ restore stack
  call _open_file
  call _read_file_data
  call _print_file_data
  call _execute_code

  mov rdi, EXIT_SUCCESS
  jmp _exit

_not_enough_args:
  mov rax, 1 ; sys_write
  mov rdi, 1 ; stdout
  mov rsi, not_enough_arg_text
  mov rdx, not_enough_arg_len
  syscall
  mov rdi, EXIT_FAILURE
  jmp _exit

_exit:
  ; exit
  mov rax, 60 ; sys_exit
  ; mov rdi, 0 ; code 0 (set earlier)
  syscall

_execute_code:
  ;lea rdi, [buf] ; address of buffer
  xor rcx, rcx
  xor r8, r8 ; keep track of current cell
_execute_code_loop:
  inc rcx
  cmp byte [buf+rcx-1], '>'
  je pointer_right
  cmp byte [buf+rcx-1], '<'
  je pointer_left
  cmp byte [buf+rcx-1], '+'
  je increment
  cmp byte [buf+rcx-1], '-'
  je decrement
  cmp byte [buf+rcx-1], '.'
  je output
  cmp byte [buf+rcx-1], ','
  je input
  cmp byte [buf+rcx-1], '['
  je left_bracket
  cmp byte [buf+rcx-1], ']'
  je right_bracket
  cmp rcx, [bufsize]
  jne _execute_code_loop
  ret
pointer_right:
  inc r8
  cmp rcx, [bufsize]
  jle _execute_code_loop
  ret
pointer_left:
  dec r8
  cmp rcx, [bufsize]
  jle _execute_code_loop
  ret
increment:
  inc byte [cells + r8]
  cmp rcx, [bufsize]
  jle _execute_code_loop
  ret
decrement:
  dec byte [cells + r8]
  cmp rcx, [bufsize]
  jle _execute_code_loop
  ret
output:
  mov rax, 1
  mov rdi, 1
  ;mov rsi, current_char
  mov rsi, cells
  add rsi, r8
  mov rdx, 1
  push rcx
  syscall
  pop rcx
  cmp rcx, [bufsize]
  jl _execute_code_loop
  ret
input:
  cmp rcx, [bufsize]
  jle _execute_code_loop
  ret
left_bracket:
  cmp byte [cells + r8], 0
  ; je skip_right_bracket_loop
  je skip_right_bracket_from_left_bracket
  mov rbx, [left_bracket_sp]
  mov [left_bracket_stack + rbx], rcx
  inc byte [left_bracket_sp]
  cmp rcx, [bufsize]
  jle _execute_code_loop
  ret
skip_right_bracket_from_left_bracket:
  inc rcx
  cmp byte [buf+rcx-1], '['
  je inc_num_to_match_right_bracket
  cmp byte [buf+rcx-1], ']'
  je check_matching_right_bracket
  jmp skip_right_bracket_from_left_bracket
inc_num_to_match_right_bracket:
  inc byte [num_to_match_right_bracket]
  jmp skip_right_bracket_from_left_bracket
check_matching_right_bracket:
  cmp byte [num_to_match_right_bracket], 0
  jne dec_matching_right_bracket
  jmp _execute_code_loop
dec_matching_right_bracket:
  dec byte [num_to_match_right_bracket]
  jmp skip_right_bracket_from_left_bracket
right_bracket:
  mov rbx, [left_bracket_sp]
  mov rcx, 0
  mov cl, byte [left_bracket_stack + rbx - 1] ; set cl to 000000...byte
  dec byte [left_bracket_sp]
  dec rcx ; gets incremented again at the beginning of the loop
  cmp rcx, [bufsize]
  jle _execute_code_loop
  ret

_open_file:
  mov rax, 2 ; sys_open
  ;mov rdi, bf_file ; open path (set earlier)
  mov rsi, O_RDONLY ; read-only
  mov rdx, 0644o
  syscall
  mov [fd_in], rax ; move file descriptor to data at fd_in
  ret ; rax has the file descriptor

_read_file_data:
  mov rax, 0 ; sys_read
  mov rdi, [fd_in] ; file descriptor of file in _open_file
  mov rsi, buf
  mov rdx, [bufsize]
  syscall
  ret

_print_file_data:
  mov rax, 1 ; sys_write
  mov rdi, 1 ; stdout
  mov rsi, buf
  mov rdx, [bufsize]
  syscall
  ret
