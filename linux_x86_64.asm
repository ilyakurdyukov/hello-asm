; -*- tab-width: 8 -*-
; nasm -f bin -O9 linux_x86.asm -o hello && chmod +x hello

%ifndef PIE
%define PIE 1
%endif

; args: rax rdi rsi rdx r10 r8 r9
; clobbers: rcx r10

%define SYS_read 0
%define SYS_write 1
%define SYS_mmap 9
%define SYS_exit 60

BITS 64
%if PIE
ORG 0
%else
ORG 0x400000
%endif

section .text

_code_seg:
_elf:	db 0x7f,'ELF',2,1,1,0	; e_ident
	dq 0
	dw 2 + PIE		; e_type
	dw 62			; e_machine
	dd 1			; e_version
	dq _start		; e_entry
	dq .ph-_elf		; e_phoff
	dq 0			; e_shoff
	dd 0			; e_flags
	dw 0x40			; e_ehsize
	dw 0x38, 1		; e_phentsize, e_phnum
	dw 0x40, 0		; e_shentsize, e_shnum
	dw 0			; e_shstrndx
.ph:	dd 1, 5			; p_type, p_flags
	dq 0			; p_offset
	dq _code_seg			; p_vaddr
	dq _code_seg			; p_paddr
	dq _code_end-_code_seg		; p_filesz
	dq _code_end-_code_seg		; p_memsz
	dq 0x1000			; p_align

_hello:	db `Hello, World!\n`
_hello_len equ $ - _hello

align 8, db 0
_start:
	mov	edx, _hello_len
%if PIE
	lea	rsi, [rel _hello]
%else
	mov	esi, _hello
%endif
	mov	edi, 1		; stdout
	mov	eax, SYS_write
	syscall

	xor	edi, edi
	mov	eax, SYS_exit
	syscall
_code_end:

