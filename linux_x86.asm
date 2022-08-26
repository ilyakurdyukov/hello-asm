; -*- tab-width: 8 -*-
; nasm -f bin -O9 linux_x86.asm -o hello && chmod +x hello

%ifndef PIE
%define PIE 1
%endif

; args: eax ebx ecx edx esi edi ebp
; ret: eax edx

%define SYS_exit 1
%define SYS_read 3
%define SYS_write 4
%define SYS_mmap 90

BITS 32
%if PIE
ORG 0
%else
ORG 0x400000
%endif

section .text

_code_seg:
_elf:	db 7Fh,'ELF',1,1,1,0	; e_ident
	dq 0
	dw 2 + PIE		; e_type
	dw 3			; e_machine
	dd 1			; e_version
	dd _start		; e_entry
	dd .ph - _elf		; e_phoff
	dd 0			; e_shoff
	dd 0			; e_flags
	dw 0x34			; e_ehsize
	dw 0x20, 1		; e_phentsize, e_phnum
	dw 0x28, 0		; e_shentsize, e_shnum
	dw 0			; e_shstrndx
.ph:	dd 1			; p_type
	dd 0			; p_offset
	dd _code_seg			; p_vaddr
	dd _code_seg			; p_paddr
	dd _code_end - _code_seg	; p_filesz
	dd _code_end - _code_seg	; p_memsz
	dd 5, 0x1000			; p_flags, p_align

_hello:	db `Hello, World!\n`
_hello_len equ $ - _hello

align 8, db 0
_start:
%if PIE
	call	_ip
_ip:	pop	ebp
%endif

	mov	edx, _hello_len
%if PIE
	lea	ecx, [ebp + (_hello - _ip)]
%else
	mov	ecx, _hello
%endif
	mov	ebx, 1		; stdout
	mov	eax, SYS_write
	int	0x80

	xor	ebx, ebx
	mov	eax, SYS_exit
	int	0x80
_code_end:

