section .data
  path_req db "path of file: "
  path_req_len equ $-path_req
  test_filename db "test.bf", 0x0

  bufsize dw 1024

  O_RDONLY equ 0
  O_WRONLY equ 1
  O_RDWR   equ 2

  NUM_CELLS equ 30000

  FALSE equ 0
  TRUE  equ 1

section .bss
  path  resb 16
  buf   resb 1024
  fd_in resb 1
  current_char resb 1
  in_brackets  resb 1

  cells resb NUM_CELLS

section .text
  global _start ; define entrypoint for ld

_start:
  mov byte [in_brackets], 0

  call _open_file
  call _read_file_data
  call _print_file_data
  call _execute_code

  ; exit
  mov rax, 60 ; sys_exit
  mov rdi, 0 ; code 0
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
  cmp rcx, [bufsize]
  jle _execute_code_loop
  ret
right_bracket:
  cmp rcx, [bufsize]
  jle _execute_code_loop
  ret
; _get_path:
;   mov rax, 0
;   mov rdi, 0
;   mov rsi, path
;   mov rdx, 16
;   syscall
;   ret
;
; _print_path_req:
;   mov rax, 1 ; sys_write
;   mov rdi, 1 ; stdout
;   mov rsi, path_req ; pointer to path_req
;   mov rdx, path_req_len ; length of path_req
;   syscall
;   ret
;
; _print_path:
;   mov rax, 1
;   mov rdi, 1
;   mov rsi, path
;   mov rdx, 16
;   syscall
;   ret

_open_file:
  mov rax, 2 ; sys_open
  mov rdi, test_filename ; open path
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
